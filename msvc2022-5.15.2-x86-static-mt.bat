@echo off

rem Set Env Variables
set qt_version=5.15.2
set nasm_folder=%~dp0tools\nasm-2.15.05\
set perl_folder=%~dp0tools\strawberry-perl-5.32.0.1-64bit\
set gperf_folder=%~dp0tools\gperf-3.0.1-bin\
set win_flex_bison_folder=%~dp0tools\win_flex_bison-2.5.24\
set llvm_folder=%~dp0tools\LLVM-11.0.1-x86\
set python2_folder=%~dp0tools\Python27\
set vcvarsall_path=C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat
set target_platform=x86
set vcvarsall_param=x64_x86
set type=static
set vc_runtime=mt
set qt_src_folder=C:\Qt\5.15.2\Src\
set prefix_folder=%~dp0Qt5.15.2-VS2022-MT-Output\
set build_temp_folder=%~dp0Qt5.15.2-VS2022-MT-Temp

rem OpenSSL
set openssl_base_folder=%~dp0openssl\1.1.1i\
set openssl_include_folder=%openssl_base_folder%include
set openssl_libs_folder=%openssl_base_folder%lib\msvc-%target_platform%-%type%-%vc_runtime%
set openssl_bin_folder=%openssl_base_folder%bin

rem Set Path Environment
set append_path=%nasm_folder%;%perl_folder%\perl\bin;%perl_folder%\perl\site\bin;%gperf_folder%\bin;%win_flex_bison_folder%;%python2_folder%;%python2_folder%\Scripts

set Path=%append_path%;%Path%
set LLVM_INSTALL_DIR=%llvm_folder%

rem VC++ Env
call "%vcvarsall_path%" %vcvarsall_param%

mkdir %build_temp_folder%
cd /d %build_temp_folder%

rem Qt Configure
call "%qt_src_folder%\configure.bat" -silent -debug-and-release -force-debug-info -strip -opensource -confirm-license ^
    -platform win32-msvc -static -static-runtime -no-opengl -no-dbus -no-icu ^
    -nomake examples -nomake tests -skip qtwebengine -skip qtlocation ^
    -qt-harfbuzz -qt-freetype -qt-zlib -qt-doubleconversion -qt-zlib -qt-libpng -qt-libjpeg -qt-pcre ^
    -mp -optimize-size -ltcg -no-pch ^
    -prefix %prefix_folder% ^
    -openssl-linked -I %openssl_include_folder% -L %openssl_libs_folder% ^
    OPENSSL_LIBS="-lUser32 -lAdvapi32 -lGdi32 -lWS2_32 -lCRYPT32 -llibcrypto32 -llibssl32"

rem Compile and install
nmake
nmake install

pause