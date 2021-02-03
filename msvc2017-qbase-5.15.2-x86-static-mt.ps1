$qt_version = "5.15.2"
$cur_script_folder = Split-Path -Parent $MyInvocation.MyCommand.Definition
$nasm_folder = Join-Path $cur_script_folder "tools\nasm-2.15.05"
$perl_folder = Join-Path $cur_script_folder "tools\strawberry-perl-5.32.0.1-64bit"
$gperf_folder = Join-Path $cur_script_folder "tools\gperf-3.0.1-bin"
$win_flex_bison_folder = Join-Path $cur_script_folder "tools\win_flex_bison-2.5.24"
$llvm_folder = Join-Path $cur_script_folder "tools\LLVM-11.0.1-x86"
$python2_folder = Join-Path $cur_script_folder "tools\Python27"
$vcvarsall_path = "C:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools\VC\Auxiliary\Build\vcvarsall.bat"
$target_platform = "x86"
$vcvarsall_param = "x64_x86"
$type = "static"
$vc_runtime = "mt"
$qt_src_folder = Join-Path $cur_script_folder "qt5-source"
$prefix_folder = Join-Path $cur_script_folder "output3"
$build_temp_folder = Join-Path $cur_script_folder "temp3"

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
echo "evn:path: $env:Path"


If(Test-Path "$prefix_folder") {
    Write-Warning "Qt prefix folder already exist. If you continue, files will be overwritten!"
    exit
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

#& "$qt_src_folder\qtbase\configure.bat" -platform win32-msvc -list-features
#& "$qt_src_folder\qtbase\configure.bat" --help

& "$qt_src_folder\qtbase\configure.bat" -silent -debug-and-release -opensource -confirm-license `
    -platform win32-msvc -static -static-runtime `
    -nomake examples -nomake tests -make libs `
    -mp -optimize-size -strip -ltcg -no-pch `
    -skip qt3d -skip qtquick3d -skip qtactiveqt -skip qtandroidextras -skip qtcanvas3d -skip qtcharts -skip qtconnectivity `
    -skip qtdatavis3d -skip qtdoc -skip qtdocgallery -skip qtfeedback -skip qtgamepad -skip qtlocation -skip qtdeclarative `
    -skip qtpurchasing -skip qtquickcontrols -skip qtquickcontrols2 -skip qtqa -skip qtrepotools -skip qtwebsockets `
    -skip qtremoteobjects -skip qtscxml -skip qtsensors -skip qtserialbus -skip qtquicktimeline `
    -skip qtspeech -skip qtvirtualkeyboard -skip qtwebview -skip qtwebengine -skip webchannel -skip qtpim `
    -skip qtwebglplugin -skip qtwayland -skip qtxmlpatterns -skip qtx11extras `
    -skip qtscript -skip qtmacextras `
    -no-harfbuzz -no-freetype -qt-doubleconversion  `
    -no-opengl -no-egl -no-angle -no-combined-angle-lib -no-libudev -no-evdev -no-libinput -no-mtdev -no-tslib `
    -no-bundled-xcb-xinput -no-xkbcommon `
    -no-dbus -no-icu -no-sql-sqlite -no-sql-sqlite2 -no-sql-odbc `
    -qt-zlib -qt-libpng -qt-libjpeg `
    -no-feature-graphicseffect -no-feature-graphicsview 
    -prefix $prefix_folder `
    -openssl-linked -I $openssl_include_folder -L $openssl_libs_folder `
    OPENSSL_LIBS="-lUser32 -lAdvapi32 -lGdi32 -lWS2_32 -lCRYPT32 -llibcrypto32 -llibssl32"

pause

# Compile.
nmake
nmake install

# Copy OpenSSL.
cp "$openssl_libs_folder\*" "$prefix_folder\lib\" -Recurse
cp "$openssl_include_folder\openssl" "$prefix_folder\include\" -Recurse

# Fixup OpenSSL DLL paths and MySQL paths.
$openssl_libs_folder_esc = $openssl_libs_folder -replace '\\','\\'

gci -r -include "*.prl" $prefix_folder | foreach-object { $a = $_.fullname; (get-content $a).Replace($openssl_libs_folder_esc, '$$$$[QT_INSTALL_LIBS]\\') | set-content $a }

popd