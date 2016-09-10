function Show-About{
  $Script:xaml = Get-Content "\XAML\AboutWindow.xaml"
  #Load XAML
  $Script:Reader=(New-Object System.Xml.XmlNodeReader $xaml)
  $Script:Window=[Windows.Markup.XamlReader]::Load($Reader)
  $Script:CloseButton = $Window.FindName('CloseButton')
  $Script:GitHubLink = $Window.FindName('GitHubLink')
  $CloseButton.Add_Click({
    $Window.Close
  })
  $GitHubLink.Add_Click({
    start "http://www.GitHub.com/LogoiLab/DirChat"
  })
  $Window.showDialog()
}
