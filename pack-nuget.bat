REM Run this from a Visual Studio 2017-or-later Developer Command Prompt.
REM
REM The previously hardcoded %windir%\Microsoft.NET\Framework\v4.0.30319\msbuild.exe cannot build
REM this solution any more: MSBuild 4.0 does not understand TargetFrameworkVersion v4.6.2, which
REM the modern log4net.ElasticSearch project now targets.
REM
REM Building the whole solution also requires the v3.5, v4.0 and v4.6.2 .NET Framework targeting
REM packs to be installed, because the legacy net35/net40 projects are part of it.
REM
REM The shared sources use C# 6 syntax, so a Roslyn compiler (MSBuild 14+) is required for the
REM legacy targets too - the .NET 4.0-era msbuild cannot compile them.
REM To build only the maintained target, use:
REM   msbuild src\log4net.ElasticSearch\log4net.ElasticSearch.csproj /t:Rebuild /p:Configuration=Release

rmdir /S bin
msbuild src\log4net.ElasticSearch.sln /t:Clean,Rebuild /p:Configuration=Release /fileLogger
%~dp0src\packages\NUnit.Runners.2.6.3\tools\nunit-console.exe -noxml -nodots -labels %~dp0src\log4net.ElasticSearch.Tests\bin\Release\log4stash.Tests.dll

copy LICENSE bin
copy readme.txt bin

src\.nuget\NuGet.exe pack log4stash.nuspec -Basepath bin
