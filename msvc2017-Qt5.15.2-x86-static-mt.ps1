$qt_version = "5.15.2"
$cur_script_folder = Split-Path -Parent $MyInvocation.MyCommand.Definition
$nasm_folder = Join-Path $cur_script_folder "tools\nasm-2.15.05"
$perl_folder = Join-Path $cur_script_folder "tools\strawberry-perl-5.32.0.1-64bit"
$gperf_folder = Join-Path $cur_script_folder "tools\gperf-3.0.1-bin"
$win_flex_bison_folder = Join-Path $cur_script_folder "tools\win_flex_bison-2.5.24"
$vcvarsall_path = "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvarsall.bat"
$target_platform = "x86"
$type = "static"
$vc_runtime = "mt"
$qt_src_folder = Join-Path $cur_script_folder "qt5-source"
$prefix_folder = Join-Path $cur_script_folder ("msvc2017-Qt" + $qt_version + "-" + $target_platform + "-" + $type + "-" + $vc_runtime)
$build_temp_folder = $prefix_folder + "-temp"

# OpenSSL
$openssl_base_folder =  Join-Path $cur_script_folder "openssl\1.1.1i"
$openssl_include_folder = Join-Path $openssl_base_folder "include"
$openssl_libs_folder = Join-Path $openssl_base_folder ("lib\msvc-" + $target_platform + "-" + $type + "-" + $vc_runtime)
$openssl_bin_folder = Join-Path $openssl_base_folder "bin"


# Set Path Environment
$env:Path += ";$nasm_folder"
$env:Path += ";$perl_folder\perl\bin"
$env:Path += ";$perl_folder\perl\site\bin"
$env:Path += ";$gperf_folder\bin"
$env:Path += ";$win_flex_bison_folder"

# Echo
echo "qt_version: $qt_version"
echo "qt_src_folder: $qt_src_folder"
echo "build_temp_folder: $build_temp_folder"
echo "perl_folder: $perl_folder"
echo "nasm_folder: $nasm_folder"
echo "gperf_folder: $gperf_folder"
echo "win_flex_bison_folder: $win_flex_bison_folder"
echo "vcvarsall_path: $vcvarsall_path"
echo "openssl_include_folder: $openssl_include_folder"
echo "openssl_libs_folder: $openssl_libs_folder"
echo "prefix_folder: $prefix_folder"

pause

If(!(Test-Path "$openssl_include_folder")) {
    Write-Warning "openssl include folder not exist"
    exit
}

If(!(Test-Path "$openssl_libs_folder")) {
    Write-Warning "openssl libs folder not exist"
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
Invoke-BatchFile $vcvarsall_path $target_platform
If(!(Test-Path "$build_temp_folder")) {
    mkdir $build_temp_folder
}
pushd $build_temp_folder

& "$qt_src_folder\configure.bat" -silent -debug-and-release -opensource -confirm-license `
    -platform win32-msvc2017 -opengl dynamic -no-iconv -no-dbus -no-icu `
    -no-fontconfig -qt-freetype -qt-harfbuzz -qt-doubleconversion -qt-sqlite -qt-zlib -qt-libpng -qt-libjpeg -nomake examples `
    -nomake tests -skip qtdoc -skip qtgamepad -skip qtwebengine `
    -mp -optimize-size -D "JAS_DLL=0" -static -static-runtime -ltcg -no-pch `
    -prefix $prefix_folder `
    -openssl-linked -I $openssl_include_folder -L $openssl_libs_folder `
    OPENSSL_LIBS="-lUser32 -lAdvapi32 -lGdi32 -lWS2_32 -lCRYPT32 -llibcrypto32 -llibssl32"
pause

# Compile.
nmake
pause
nmake install


# Copy OpenSSL.
cp "$openssl_libs_folder\*" "$prefix_folder\lib\" -Recurse
cp "$openssl_include_folder\openssl" "$prefix_folder\include\" -Recurse


# Fixup OpenSSL DLL paths and MySQL paths.
$openssl_libs_folder_esc = $openssl_libs_folder -replace '\\','\\'

gci -r -include "*.prl" $prefix_folder | foreach-object { $a = $_.fullname; (get-content $a).Replace($openssl_libs_folder_esc, '$$$$[QT_INSTALL_LIBS]\\') | set-content $a }

popd