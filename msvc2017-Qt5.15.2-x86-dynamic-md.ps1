$qt_version = "5.15.2"
$cur_script_folder = Split-Path -Parent $MyInvocation.MyCommand.Definition
$nasm_folder = Join-Path $cur_script_folder "nasm-2.15.05"
$perl_folder = Join-Path $cur_script_folder "Strawberry\perl\bin"
$vcvarsall_path = "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvarsall.bat"
$target_platform = "x86"
$type = "dynamic"
$vc_runtime = "md"
$qt_src_folder = Join-Path $cur_script_folder "qt5-source"
$prefix_folder = Join-Path $cur_script_folder ("msvc2017-Qt" + $qt_version + "-" + $target_platform + "-" + $type + "-" + $vc_runtime)
$build_folder = $prefix_folder + "-temp"

# OpenSSL
$openssl_base_folder =  Join-Path $cur_script_folder "openssl\1.1.1i"
$openssl_include_folder = Join-Path $openssl_base_folder "include"
$openssl_libs_folder = Join-Path $openssl_base_folder ("lib\msvc-" + $target_platform + "-" + $type + "-" + $vc_runtime)
$openssl_bin_folder = Join-Path $openssl_base_folder "bin"


mkdir $qt_src_folder
$directoryInfo = Get-ChildItem $qt_src_folder | Measure-Object
If($directoryInfo.count -eq 0) {
    git clone -b $qt_version "git://code.qt.io/qt/qt5.git" $qt_src_folder
}
else {
    cd $qt_src_folder
    git pull
    git checkout $qt_version
}
git submodule update --init --recursive
git branch -vv


# Configure.
Invoke-BatchFile $vcvarsall_path $target_platform
mkdir $build_folder
cd $build_folder

& "$qt_src_folder\configure.bat" -debug-and-release -opensource -confirm-license `
    -platform win32-msvc2017 -opengl desktop -no-iconv -no-dbus -no-icu `
    -no-fontconfig -no-freetype -qt-harfbuzz -qt-doubleconversion -nomake examples `
    -nomake tests -skip qt3d -skip qtactiveqt -skip qtcanvas3d -skip qtconnectivity `
    -skip qtdatavis3d -skip qtdoc -skip qtgamepad -skip qtgraphicaleffects -skip qtlocation `
    -skip qtnetworkauth -skip qtpurchasing -skip qtquickcontrols -skip qtquickcontrols2 `
    -skip qtremoteobjects -skip qtscxml -skip qtsensors -skip qtserialbus -skip qtserialport `
    -skip qtspeech -skip qtvirtualkeyboard -skip qtwebview -skip qtscript -skip qtwebengine `
    -mp -optimize-size -D "JAS_DLL=0" -shared -feature-relocatable -ltcg `
    -prefix $prefix_folder `
    -openssl-linked -I $openssl_include_folder -L $openssl_libs_folder `
    OPENSSL_LIBS="-lUser32 -lAdvapi32 -lGdi32 -lWS2_32 -lCRYPT32 -llibcrypto32 -llibssl32"


# Compile.
nmake
nmake install


# Copy OpenSSL.
cp "$openssl_libs_folder\*" "$prefix_folder\lib\" -Recurse
cp "$openssl_include_folder\openssl" "$prefix_folder\include\" -Recurse


# Fixup OpenSSL DLL paths and MySQL paths.
$openssl_libs_folder_esc = $openssl_libs_folder -replace '\\','\\'

gci -r -include "*.prl" $prefix_folder | foreach-object { $a = $_.fullname; (get-content $a).Replace($openssl_libs_folder_esc, '$$$$[QT_INSTALL_LIBS]\\') | set-content $a }
