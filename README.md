# 1. About
Compile x86/x64 Qt 5/6 library.

# 2. How to use
## 2.1 Install Pscx
Install [Pscx](https://github.com/Pscx/Pscx):
```powershell
Install-Module Pscx -Scope CurrentUser
```

If you already have installed Pscx from the PowerShell Gallery, you can update Pscx with the command:
```powershell
Update-Module Pscx
```

## 2.2 Run Script
For example:
```powershell
powershell -ExecutionPolicy RemoteSigned -File msvc2017-Qt5.15.2-x86-static-mt.ps1
```