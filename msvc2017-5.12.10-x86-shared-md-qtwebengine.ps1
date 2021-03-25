$qt_version = "5.12.10"
$cur_script_folder = Split-Path -Parent $MyInvocation.MyCommand.Definition
$nasm_folder = Join-Path $cur_script_folder "tools\nasm-2.15.05"
$perl_folder = Join-Path $cur_script_folder "tools\strawberry-perl-5.32.0.1-64bit"
$gperf_folder = Join-Path $cur_script_folder "tools\gperf-3.0.1-bin"
$win_flex_bison_folder = Join-Path $cur_script_folder "tools\win_flex_bison-2.5.24"
$llvm_folder = Join-Path $cur_script_folder "tools\LLVM-11.0.1-x86"
$python2_folder = Join-Path $cur_script_folder "tools\Python27"
$vcvarsall_path = "C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\VC\Auxiliary\Build\vcvarsall.bat"
$target_platform = "x86"
$vcvarsall_param = "x64_x86"
$type = "shared"
$vc_runtime = "md"
$qt_src_folder = "C:\Qt\Qt5.12.10\5.12.10\Src" # Use already exist pre-download source files.
$prefix_folder = Join-Path $cur_script_folder "output"
$build_temp_folder = Join-Path $cur_script_folder "temp"

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

If(!(Test-Path "$openssl_include_folder")) {
    Write-Warning "openssl include folder not exist!"
    exit
}

If(!(Test-Path "$openssl_libs_folder")) {
    Write-Warning "openssl libs folder not exist!"
    exit
}

# Configure.
Invoke-BatchFile $vcvarsall_path $vcvarsall_param

# Build Temp Folder
If(!(Test-Path "$build_temp_folder")) {
    mkdir $build_temp_folder
}
pushd $build_temp_folder

cd "$qt_src_folder\qtwebengine"

# Using qmake to compile qtwebengine module.
& "C:\Qt\Qt5.12.10\5.12.10\msvc2017\bin\qmake.exe" -- -webengine-proprietary-codecs

# Compile.
nmake

# Will copy *.lib or *.dll to C:\Qt\Qt5.12.10\5.12.10\msvc2017 folders.
nmake install

popd