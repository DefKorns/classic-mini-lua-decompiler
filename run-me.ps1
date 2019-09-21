#
#  Copyright 2019 DefKorns (https://github.com/DefKorns/classic-mini-lua-decompiler/LICENSE)
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
$FolderPath = Get-Location;
$ModulesPath="$FolderPath/modules"
$LuaPath = "$FolderPath/encoded/resources";
$DecodedPath = "$FolderPath/decoded";
$RecodedPath = "$FolderPath/recoded";
$DecompilerPath = "$ModulesPath/decompiler/main.py";
$LuaJit = "$ModulesPath/luajit"
$env:LUA_DIR = "$LuaJit"
$env:LUA_CPATH = "?.dll;$env:LUA_DIR\?.dll"
$env:LUA_PATH = "?.lua;$env:LUA_DIR\jit\?.lua;$env:LUA_DIR\?.lua"

function Show-Menu {
	param (
		[string]$Title = 'Classic Mini Lua De/Encoder'
	)
	Clear-Host
	Write-Host "================ $Title ================"
    
	Write-Host "1: Press 'D' to decode lua files"
	Write-Host "2: Press 'E' to re-encode lua files."
	Write-Host "Q: Press 'Q' to quit."
}

do {
	Show-Menu
	$input = Read-Host "Please make a selection"
	switch ($input) {
		'D' {
			Clear-Host
			robocopy $LuaPath $DecodedPath *.lua /mir /sec /nfl /njh /njs /ndl /nc /ns /np

			Get-ChildItem "$DecodedPath" -recurse | Where-Object { $_.PSIsContainer -and `
				@(Get-ChildItem -Lit $_.Fullname -r | Where-Object { !$_.PSIsContainer }).Length -eq 0 } |
			Remove-Item -recurse

			Get-ChildItem -Path $DecodedPath -File -Recurse |
			Where-Object { $_.Extension -eq '.lua' } |
			ForEach-Object {
				Try {
					$DecFile = $_.FullName + '.dec'
					Write-Host "$(Get-Date -UFormat '%Y-%m-%d %H:%M:%S'):"$_.FullName":"
					python $DecompilerPath.ToString() --file $_.FullName --output $DecFile --catch_asserts
				}
				Catch {
					Write-Host "Catch me if you can!"
				}
				Remove-Item -Path $_.FullName
			}
			return
		} 'E' {
			Clear-Host
			robocopy $DecodedPath $RecodedPath *.dec /mir /sec /nfl /njh /njs /ndl /nc /ns /np

			Get-ChildItem "$RecodedPath" -recurse | Where-Object { $_.PSIsContainer -and `
				@(Get-ChildItem -Lit $_.Fullname -r | Where-Object { !$_.PSIsContainer }).Length -eq 0 } |
			Remove-Item -recurse

			Get-ChildItem -Path $RecodedPath -File -Recurse |
			Where-Object { $_.Extension -eq '.dec' } |
			ForEach-Object {
				Try {
					$DecFile = $_.FullName
					$RecFile = $_.DirectoryName+'\'+$_.BaseName

					Write-Host "$(Get-Date -UFormat '%Y-%m-%d %H:%M:%S'):"$RecFile":"
					& $LuaJit/luajit.exe -b $DecFile $RecFile
				}
				Catch {
					Write-Host "Catch me if you can!"
				}
				Remove-Item -Path $DecFile
			}
			return
		} 'q' {
			return
		}
	}
	pause
}
until ($input -eq 'q')