$qt_version = "5.15.2"
$cur_script_folder = Split-Path -Parent $MyInvocation.MyCommand.Definition
$nasm_folder = Join-Path $cur_script_folder "tools\nasm-2.15.05"
$perl_folder = Join-Path $cur_script_folder "tools\strawberry-perl-5.32.0.1-64bit"
$gperf_folder = Join-Path $cur_script_folder "tools\gperf-3.0.1-bin"
$win_flex_bison_folder = Join-Path $cur_script_folder "tools\win_flex_bison-2.5.24"
$llvm_folder = Join-Path $cur_script_folder "tools\LLVM-11.0.1-x86"
$python2_folder = Join-Path $cur_script_folder "tools\Python27"
$vcvarsall_path = "C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\VC\Auxiliary\Build\vcvarsall.bat"
$target_platform = "x86"
$vcvarsall_param = "x86"
$type = "static"
$vc_runtime = "mt"
$qt_src_folder = Join-Path $cur_script_folder "qt5-source"
$prefix_folder = Join-Path $cur_script_folder "qt5base-mt-min"
$build_temp_folder = Join-Path $cur_script_folder "temp-qt5base-mt-min"

# OpenSSL
$openssl_base_folder =  Join-Path $cur_script_folder "openssl\1.1.1i"
$openssl_include_folder = Join-Path $openssl_base_folder "include"
$openssl_libs_folder = Join-Path $openssl_base_folder ("lib\msvc-" + $target_platform + "-" + $type + "-" + $vc_runtime)
$openssl_bin_folder = Join-Path $openssl_base_folder "bin"


# Set Path Environment
$append_path = "$nasm_folder" + 
    ";$perl_folder\perl\bin" +
    ";$perl_folder\perl\site\bin" +
    ";$gperf_folder\bin" +
    ";$win_flex_bison_folder" +
    ";$python2_folder" +
    ";$python2_folder\Scripts";

$env:Path = $append_path + $env:Path
$env:LLVM_INSTALL_DIR = "$llvm_folder"

# Echo
echo "qt_version: $qt_version"
echo "qt_src_folder: $qt_src_folder"
echo "build_temp_folder: $build_temp_folder"
echo "perl_folder: $perl_folder"
echo "nasm_folder: $nasm_folder"
echo "gperf_folder: $gperf_folder"
echo "llvm_folder: $llvm_folder"
echo "python2_folder: $python2_folder"
echo "win_flex_bison_folder: $win_flex_bison_folder"
echo "vcvarsall_path: $vcvarsall_path"
echo "openssl_include_folder: $openssl_include_folder"
echo "openssl_libs_folder: $openssl_libs_folder"
echo "prefix_folder: $prefix_folder"
#echo "evn:path: $env:Path"


If(Test-Path "$prefix_folder") {
    Write-Warning "Qt prefix folder already exist. If you continue, files will be overwritten!"
    #exit
}

If(!(Test-Path "$openssl_include_folder")) {
    Write-Warning "openssl include folder not exist!"
    exit
}

If(!(Test-Path "$openssl_libs_folder")) {
    Write-Warning "openssl libs folder not exist!"
    exit
}

# Clone Qt Source
If(!(Test-Path "$qt_src_folder")) {
    mkdir $qt_src_folder
}
$directoryInfo = Get-ChildItem $qt_src_folder | Measure-Object
If($directoryInfo.count -eq 0) {
    git clone -b $qt_version "git://code.qt.io/qt/qt5.git" $qt_src_folder
    pushd $qt_src_folder
    git submodule update --init --recursive
    popd
}
else {
    pushd $qt_src_folder
    git checkout $qt_version
    git pull
    git submodule update --recursive
    popd
}


# Configure.
Invoke-BatchFile $vcvarsall_path $vcvarsall_param

# Build Temp Folder
If(!(Test-Path "$build_temp_folder")) {
    mkdir $build_temp_folder
}
pushd $build_temp_folder

# & "$qt_src_folder\qtbase\configure.bat" --help

# & "$qt_src_folder\qtbase\configure.bat" -platform win32-msvc -list-features

& "$qt_src_folder\qtbase\configure.bat" -silent -debug-and-release -opensource -confirm-license `
    -platform win32-msvc -static -static-runtime -no-pch -no-opengl -no-dbus -no-icu -no-sql-sqlite -no-sql-sqlite2 -no-sql-odbc `
    -no-harfbuzz -no-zlib -no-iconv -no-eventfd -no-inotify -no-feature-concurrent -no-feature-network -no-feature-sql -no-feature-xml `
    -no-system-proxies -no-schannel -no-ssl -no-openssl `
    -nomake examples -nomake tests -nomake tools -make libs `
    -no-feature-bearermanagement `
    -no-feature-appstore-compliant `
    -no-feature-big_codecs `
    -no-feature-codecs `
    -no-feature-commandlineparser `
    -no-feature-completer `
    -no-feature-concatenatetablesproxymodel `
    -no-feature-cups `
    -no-feature-desktopservices `
    -no-feature-dial `
    -no-feature-dnslookup `
    -no-feature-dockwidget `
    -no-feature-dom `
    -no-feature-dtls `
    -no-feature-freetype `
    -no-feature-fscompleter `
    -no-feature-ftp `
    -no-feature-future `
    -no-feature-gestures `
    -no-feature-http `
    -no-feature-identityproxymodel `
    -no-feature-im `
    -no-feature-image_heuristic_mask `
    -no-feature-image_text `
    -no-feature-imageformat_ppm `
    -no-feature-keysequenceedit `
    -no-feature-localserver `
    -no-feature-netlistmgr `
    -no-feature-networkdiskcache `
    -no-feature-networkinterface `
    -no-feature-networkproxy `
    -no-feature-ocsp `
    -no-feature-pdf `
    -no-feature-picture `
    -no-feature-printdialog `
    -no-feature-printer `
    -no-feature-printpreviewdialog `
    -no-feature-printpreviewwidget `
    -no-feature-process `
    -no-feature-processenvironment `
    -no-feature-sessionmanager `
    -no-feature-sharedmemory `
    -no-feature-socks5 `
    -no-feature-splashscreen `
    -no-feature-sqlmodel `
    -no-feature-sspi `
    -no-feature-statemachine `
    -no-feature-syntaxhighlighter `
    -no-feature-textbrowser `
    -no-feature-texthtmlparser `
    -no-feature-textmarkdownreader `
    -no-feature-textmarkdownwriter `
    -no-feature-textodfwriter `
    -no-feature-topleveldomain `
    -no-feature-tuiotouch `
    -no-feature-udpsocket `
    -no-feature-undocommand `
    -no-feature-undostack `
    -no-feature-undogroup `
    -no-feature-undoview `
    -no-feature-valgrind `
    -no-feature-wizard `
    -no-feature-xmlstream `
    -no-feature-xmlstreamreader `
    -no-feature-xmlstreamwriter `
    -qt-libpng -qt-libjpeg `
    -mp -optimize-size -strip -ltcg `
    -prefix $prefix_folder
     
# Compile.
nmake
nmake install

popd