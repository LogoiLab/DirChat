$xaml = Get-Content "\XAML\ClubbCreateWindow.xaml"
#Load XAML
$reader=(New-Object System.Xml.XmlNodeReader $xaml)
$Window=[Windows.Markup.XamlReader]::Load($reader)
$Window.showDialog()
