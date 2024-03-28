Out-Null

#Check whether voicemeeter*.exe is running
IF (!(Get-Process audiodg))
{
  Write-Output "audiodg is not running.. Start-Processing.."
  Start-Process -f C:\Windows\System32\audiodg.exe
}
IF (!(Get-Process voicemeeter*))
{
  Write-Output "Voicemeeter is not running.."
  Write-Output "Please start voicemeeter and run script again.."
  exit
} ELSE
{
  #Set cpu priority on high and change affinity to a single cpu core for audio device graph
  $procdg = Get-Process audiodg
  $procdg.ProcessorAffinity=1
  $procdg.PriorityClass="128"

  #Getting Voicemeeter info
  $procvmtr = Get-Process voicemeeter*
  $procvmtrid = $procvmtr.Id
  $vmtrcl = (Get-WmiObject Win32_Process -Filter "Handle=$procvmtrid").CommandLine

  #Killing and Start-Processing voicemeeter audio engine
  $procvmtr.Kill()
  $procvmtr.WaitForExit()
  Start-Process -f $vmtrcl.Replace('"',"")

}
