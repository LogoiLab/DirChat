function Initialize-Window{
  param(
    [switch]$splash
  )

  $xaml = Get-Content ".\Windows\MainWindow.xaml"
  #Load XAML
  $reader=(New-Object System.Xml.XmlNodeReader $xaml)
  $Window=[Windows.Markup.XamlReader]::Load( $reader )

  ##Controls
  $MessageWindowFont = $Window.FindName("MessageWindowFont")
  $OnlineUsersFont = $Window.FindName("OnlineUsersFont")
  $InputBoxFont = $Window.FindName("InputBoxFont")
  $Script:Paragraph = $Window.FindName('Paragraph')
  $Script:OnlineUsers = $Window.FindName('OnlineUsers')
  $SendButton = $Window.FindName('Send_btn')
  $Script:Join = $Window.FindName('Connect_btn')
  $Username_txt = $Window.FindName('username_txt')
  $Clubb_txt = $Window.FindName('clubbname_txt')
  $Inputbox_txt = $Window.FindName('Input_txt')
  $Script:MainMessage = $Window.FindName('MainMessage_txt')
  $ExitMenu = $Window.FindName('ExitMenu')
  $SaveTranscript = $Window.FindName('SaveTranscript')
  $AboutMenu = $Window.FindName('AboutMenu')

  ##Events
  ##InputBox Font event
  $InputBoxFont.Add_Click({
      Invoke-FontDialog -Control $Inputbox_txt -ShowColor -FontMustExist
  })
  ##OnlineUser Font event
  $OnlineUsersFont.Add_Click({
      Invoke-FontDialog -Control $OnlineUsers -ShowColor -FontMustExist
  })
  ##MessageWindow Font event
  $MessageWindowFont.Add_Click({
      Invoke-FontDialog -Control $MainMessage -FontMustExist
  })

  #ExitMenu
  $ExitMenu.Add_Click({
      $Window.Close()
  })

  #SaveTranscriptMenu
  $SaveTranscript.Add_Click({
      Save-Transcript
  })

  #AboutMenu
  $AboutMenu.Add_Click({
      Open-PoshChatAbout
  })

  #Connect
  $ConnectButton.Add_Click({
      #Get Server IP
      $Server = $Server_txt.text

      #Get Username
      $Global:Username = $Username_txt.text
      If ($username -match "^[A-Za-z0-9_!]*$") {
          $ConnectButton.IsEnabled = $False
          $DisconnectButton.IsEnabled = $True
          If ($Server -AND $Username) {
              $Message = "Connecting to {0} as {1}" -f $Server,$username
              $Paragraph.Inlines.Add((New-ChatMessage -Message ("{0} " -f (Get-Date).ToShortDateString()) -ForeGround Black -Bold))
              $Paragraph.Inlines.Add((New-Object System.Windows.Documents.LineBreak))
              $Paragraph.Inlines.Add((New-ChatMessage -Message $message -ForeGround Green))
              $Paragraph.Inlines.Add((New-Object System.Windows.Documents.LineBreak))

              #Connect to server
              $Endpoint = new-object System.Net.IPEndpoint ([ipaddress]::any,$SourcePort)
              $TcpClient = [Net.Sockets.TCPClient]$endpoint
              Try {
                  $TcpClient.Connect($Server,15600)
                  $Global:ServerStream = $TcpClient.GetStream()
                  $data = [text.Encoding]::Ascii.GetBytes($Username)
                  $ServerStream.Write($data,0,$data.length)
                  $ServerStream.Flush()
                  If ($TcpClient.Connected) {
                      $Window.Title = ("{0}: Connected as {1}" -f $Window.Title,$Username)
                      #Kick off a job to watch for messages from clients
                      $newRunspace = [RunSpaceFactory]::CreateRunspace()
                      $newRunspace.Open()
                      $newRunspace.SessionStateProxy.setVariable("TcpClient", $TcpClient)
                      $newRunspace.SessionStateProxy.setVariable("MessageQueue", $MessageQueue)
                      $newRunspace.SessionStateProxy.setVariable("ConnectButton", $ConnectButton)
                      $newPowerShell = [PowerShell]::Create()
                      $newPowerShell.Runspace = $newRunspace
                      $sb = {
                          #Code to kick off client connection monitor and look for incoming messages.
                          $client = $TCPClient
                          $serverstream = $Client.GetStream()
                          #While client is connected to server, check for incoming traffic
                          While ($client.Connected) {
                              Try {
                                  [byte[]]$inStream = New-Object byte[] 10025
                                  $buffSize = $client.ReceiveBufferSize
                                  $return = $serverstream.Read($inStream, 0, $buffSize)
                                  If ($return -gt 0) {
                                      $Messagequeue.Enqueue([System.Text.Encoding]::ASCII.GetString($inStream[0..($return - 1)]))
                                  }
                              } Catch {
                                  #Connection to server has been closed
                                  $Messagequeue.Enqueue("~S")
                                  Break
                              }
                          }
                          #Shutdown the connection as connection has ended
                          $client.Client.Disconnect($True)
                          $client.Client.Close()
                          $client.Close()
                          $ConnectButton.IsEnabled = $True
                          $DisconnectButton.IsEnabled = $False
                      }
                      $job = "" | Select Job, PowerShell
                      $job.PowerShell = $newPowerShell
                      $Job.job = $newPowerShell.AddScript($sb).BeginInvoke()
                      $ClientConnection.$Username = $job
                  }
              } Catch {
                  #Errors Connecting to server
                  $Paragraph.Inlines.Add((New-ChatMessage -Message ("Unable to connect to {0}! Please try again later!" -f $RemoteServer) -ForeGround Red))
                  $ConnectButton.IsEnabled = $True
                  $TcpClient.Close()
                  $ClientConnection.user.PowerShell.EndInvoke($ClientConnections.user.Job)
                  $ClientConnection.user.PowerShell.Runspace.Close()
                  $ClientConnection.user.PowerShell.Dispose()
              }
          }
      } Else {
          #Username is not in correct format
          $Paragraph.Inlines.Add((New-ChatMessage -Message ("`'{0}`' is not a valid username! Acceptable characters are 'A-Za-z0-9!_'. Spaces are not allowed!" -f $username) -ForeGround Red))
          $Paragraph.Inlines.Add((New-Object System.Windows.Documents.LineBreak))
      }
  })

  #Send message
  $SendButton.Add_Click({
      #Send message to server
      If (($Inputbox_txt.Text).StartsWith("@")) {
          $Messagequeue.Enqueue(("~I{0}{1}{2}" -f $username,"~~",$Inputbox_txt.Text))
      }
      $Message = "~M{0}{1}{2}" -f $username,"~~",$Inputbox_txt.Text
      $data = [text.Encoding]::Ascii.GetBytes($Message)
      $ServerStream.Write($data,0,$data.length)
      $ServerStream.Flush()
      $Inputbox_txt.Clear()
  })

  #Load Window
  $Window.Add_Loaded({
      #Dictionary of colors for Fonts
      $script:colors = @{}
      $Color = [windows.media.colors] | Get-Member -static -Type Property | Select -Expand Name | ForEach {
          $colors["$([windows.media.colors]::$_)"] = $_
          $colors[$_] = "$([windows.media.colors]::$_)"
      }
      #Date placeholder for later use
      $Global:Date = Get-Date -Format ddMMyyyy
      #Used for managing the queue of messages in an orderly fashion
      $Global:MessageQueue =  [System.Collections.Queue]::Synchronized((New-Object System.collections.queue))
      #Used for managing client connection
      $Global:ClientConnection = [hashtable]::Synchronized(@{})
      #Create Timer object
      $Global:timer = New-Object System.Windows.Threading.DispatcherTimer
      #Fire off every 1 seconds
      $timer.Interval = [TimeSpan]"0:0:1.00"
      #Add event per tick
      $timer.Add_Tick({
          [Windows.Input.InputEventHandler]{ $Global:Window.UpdateLayout() }
          If ($Messagequeue.Count -gt 0) {
              $Message = $Messagequeue.Dequeue()
              #If a different day then when client started
              If ($date -ne (Get-Date -Format ddMMyyyy)) {
                  $date = (Get-Date -Format ddMMyyyy)
                  $Paragraph.Inlines.Add((New-ChatMessage -Message ("{0} " -f (Get-Date).ToShortDateString()) -ForeGround Black -Bold))
                  $Paragraph.Inlines.Add((New-Object System.Windows.Documents.LineBreak))
              }
              Switch ($Message) {
                  {$_.Startswith("~B")} {
                      #Message
                      $data = ($_).SubString(2)
                      $split = $data -split ("{0}" -f "~~")
                      $Paragraph.Inlines.Add((New-ChatMessage -Message ("[{0}] " -f (Get-Date).ToLongTimeString()) -ForeGround Gray))
                      $Paragraph.Inlines.Add((New-ChatMessage -Message ("{0}: " -f $split[0]) -ForeGround Black -Bold))
                      $Paragraph.Inlines.Add((New-ChatMessage -Message ("{0}" -f $split[1]) -ForeGround Orange))
                  }
                  {$_.Startswith("~I")} {
                      #Message
                      $data = ($_).SubString(2)
                      $split = $data -split ("{0}" -f "~~")
                      $Paragraph.Inlines.Add((New-ChatMessage -Message ("[{0}] " -f (Get-Date).ToLongTimeString()) -ForeGround Gray))
                      $Paragraph.Inlines.Add((New-ChatMessage -Message ("{0}: " -f $split[0]) -ForeGround Black -Bold))
                      $Paragraph.Inlines.Add((New-ChatMessage -Message ("{0}" -f $split[1]) -ForeGround Blue))
                  }
                  {$_.Startswith("~M")} {
                      #Message
                      $data = ($_).SubString(2)
                      $split = $data -split ("{0}" -f "~~")
                      $Paragraph.Inlines.Add((New-ChatMessage -Message ("[{0}] " -f (Get-Date).ToLongTimeString()) -ForeGround Gray))
                      $Paragraph.Inlines.Add((New-ChatMessage -Message ("{0}: " -f $split[0]) -ForeGround Black -Bold))
                      $Paragraph.Inlines.Add((New-ChatMessage -Message ("{0}" -f $split[1]) -ForeGround Black))
                  }
                  {$_.Startswith("~D")} {
                      #Disconnect
                      $Paragraph.Inlines.Add((New-ChatMessage -Message ("[{0}] " -f (Get-Date).ToLongTimeString()) -ForeGround Gray))
                      $Paragraph.Inlines.Add((New-ChatMessage -Message ("{0} has disconnected from the server" -f $_.SubString(2)) -ForeGround Green))
                      #Remove user from online list
                      $OnlineUsers.Items.Remove($_.SubString(2))
                  }
                  {$_.StartsWith("~C")} {
                      #Connect
                      $Message = ("{0} has connected to the server" -f $_.SubString(2))
                      $Paragraph.Inlines.Add((New-ChatMessage -Message ("[{0}] " -f (Get-Date).ToLongTimeString()) -ForeGround Gray))
                      $Paragraph.Inlines.Add((New-ChatMessage -Message $message -ForeGround Green))
                      ##Add user to online list
                      If ($Username -ne $_.SubString(2)) {
                          $OnlineUsers.Items.Add($_.SubString(2))
                      }
                  }
                  {$_.StartsWith("~S")} {
                      #Server Shutdown
                      $Paragraph.Inlines.Add((New-ChatMessage -Message ("[{0}] " -f (Get-Date).ToLongTimeString()) -ForeGround Gray))
                      $Paragraph.Inlines.Add((New-ChatMessage -Message ("SERVER HAS DISCONNECTED.") -ForeGround Red))
                      $TcpClient.Close()
                      $ClientConnection.user.PowerShell.EndInvoke($ClientConnections.user.Job)
                      $ClientConnection.user.PowerShell.Runspace.Close()
                      $ClientConnection.user.PowerShell.Dispose()
                      $ConnectButton.IsEnabled = $True
                      $DisconnectButton.IsEnabled = $False
                      $OnlineUsers.Items.Clear()
                  }
                  {$_.StartsWith("~Z")} {
                      #List of connected users
                      $online = (($_).SubString(2) -split "~~")
                      #Add online users to window
                      $Online | ForEach {
                          $OnlineUsers.Items.Add($_)
                      }
                  }
                  Default {
                      $MainMessage.text += ("[{0}] {1}" -f (Get-Date).ToLongTimeString(),$_)
                  }
              }
          $Paragraph.Inlines.Add((New-Object System.Windows.Documents.LineBreak))
          $MainMessage.ScrollToEnd()
          }
      })
      #Start timer
      $timer.Start()
      If (-NOT $timer.IsEnabled) {
          $Window.Close()
      }
  })
  #Close Window
  $Window.Add_Closed({
      If ($TcpClient) {
          $TcpClient.Close()
      }
      If ($ClientConnection.user) {
          $ClientConnection.user.PowerShell.EndInvoke($ClientConnection.user.Job)
          $ClientConnection.user.PowerShell.Runspace.Close()
          $ClientConnection.user.PowerShell.Dispose()
      }
  })

  #Disconnect from server
  $DisconnectButton.Add_Click({
      $Paragraph.Inlines.Add((New-ChatMessage -Message ("[{0}] " -f (Get-Date).ToLongTimeString()) -ForeGround Gray))
      $Paragraph.Inlines.Add((New-ChatMessage -Message ("Disconnecting from server: {0}" -f $Server) -ForeGround Red))
      $Paragraph.Inlines.Add((New-Object System.Windows.Documents.LineBreak))
      #Shutdown client runspace and socket
      $TcpClient.Close()
      $ClientConnection.user.PowerShell.EndInvoke($ClientConnection.user.Job)
      $ClientConnection.user.PowerShell.Runspace.Close()
      $ClientConnection.user.PowerShell.Dispose()
      $ConnectButton.IsEnabled = $True
      $DisconnectButton.IsEnabled = $False
      $OnlineUsers.Items.Clear()
  })

  $Window.Add_KeyDown({
      $key = $_.Key
      If ([System.Windows.Input.Keyboard]::IsKeyDown("RightCtrl") -OR [System.Windows.Input.Keyboard]::IsKeyDown("LeftCtrl")) {
          Switch ($Key) {
          "E" {$Window.Close()}
          "RETURN" {
              Write-Verbose ("Sending message")
              If (($Inputbox_txt.Text).StartsWith("@")) {
                  $Messagequeue.Enqueue(("~I{0}{1}{2}" -f $username,"~~",$Inputbox_txt.Text))
              }
              $Message = "~M{0}{1}{2}" -f $username,"~~",$Inputbox_txt.Text
              $data = [text.Encoding]::Ascii.GetBytes($Message)
              $ServerStream.Write($data,0,$data.length)
              $ServerStream.Flush()
              $Inputbox_txt.Clear()
          }
          "S" {Save-Transcript}
          Default {$Null}
          }
      }
  })

  [void]$Window.showDialog()

  }).BeginInvoke()
}
