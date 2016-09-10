function Show-MainWindow.psm1{
  $xaml = Get-Content "\XAML\MainWindow.xaml"
  #Load XAML
  $reader=(New-Object System.Xml.XmlNodeReader $xaml)
  $Window=[Windows.Markup.XamlReader]::Load($reader)
  $Window.showDialog()
}
