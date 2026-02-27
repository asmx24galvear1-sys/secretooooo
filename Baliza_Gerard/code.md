# Baliza_Gerard — Todo el Código Fuente

Este archivo contiene todos los archivos de código fuente de la carpeta `Baliza_Gerard/` concatenados.

---

## `Baliza_Gerard/BeaconActivePc.csproj`

```xml
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net8.0-windows10.0.19041.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <SupportedOSPlatformVersion>10.0.19041.0</SupportedOSPlatformVersion>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Newtonsoft.Json" Version="13.0.3" />
  </ItemGroup>

  <ItemGroup>
    <Compile Remove="BeaconGui\**" />
    <EmbeddedResource Remove="BeaconGui\**" />
    <None Remove="BeaconGui\**" />
    <Page Remove="BeaconGui\**" />
  </ItemGroup>

</Project>

```

---

## `Baliza_Gerard/BeaconGui/App.xaml`

```xml
﻿<Application x:Class="BeaconGui.App"
             xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
             xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
             xmlns:local="clr-namespace:BeaconGui"
             StartupUri="MainWindow.xaml">
    <Application.Resources>
         
    </Application.Resources>
</Application>

```

---

## `Baliza_Gerard/BeaconGui/App.xaml.cs`

```csharp
﻿using System.Configuration;
using System.Data;
using System.Windows;

namespace BeaconGui;

/// <summary>
/// Interaction logic for App.xaml
/// </summary>
public partial class App : Application
{
}


```

---

## `Baliza_Gerard/BeaconGui/AssemblyInfo.cs`

```csharp
using System.Windows;

[assembly:ThemeInfo(
    ResourceDictionaryLocation.None,            //where theme specific resource dictionaries are located
                                                //(used if a resource is not found in the page,
                                                // or application resource dictionaries)
    ResourceDictionaryLocation.SourceAssembly   //where the generic resource dictionary is located
                                                //(used if a resource is not found in the page,
                                                // app, or any theme specific resource dictionaries)
)]

```

---

## `Baliza_Gerard/BeaconGui/BeaconGui.csproj`

```xml
﻿<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <OutputType>WinExe</OutputType>
    <TargetFramework>net9.0-windows10.0.19041.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <UseWPF>true</UseWPF>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Newtonsoft.Json" Version="13.0.4" />
  </ItemGroup>

</Project>

```

---

## `Baliza_Gerard/BeaconGui/MainWindow.xaml`

```xml
﻿<Window x:Class="BeaconGui.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="GeoRacing Beacon" Height="450" Width="600"
        Background="#1E1E1E" Foreground="White">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/> <!-- Header -->
            <RowDefinition Height="Auto"/> <!-- Stats -->
            <RowDefinition Height="Auto"/> <!-- Controls -->
            <RowDefinition Height="*"/>    <!-- Logs -->
        </Grid.RowDefinitions>

        <!-- Header -->
        <TextBlock Text="GeoRacing Active Beacon" FontSize="24" FontWeight="Bold" 
                   HorizontalAlignment="Center" Foreground="#FF4D4D"/>

        <!-- Stats Panel -->
        <Border Grid.Row="1" Margin="0,20,0,20" Padding="15" Background="#2D2D2D" CornerRadius="8">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                
                <StackPanel Grid.Column="0" HorizontalAlignment="Center">
                    <TextBlock Text="STATUS" Foreground="#888" FontSize="12"/>
                    <TextBlock x:Name="StatusText" Text="STOPPED" FontSize="18" FontWeight="Bold" Foreground="#FF5555"/>
                </StackPanel>

                <StackPanel Grid.Column="1" HorizontalAlignment="Center">
                    <TextBlock Text="MODE" Foreground="#888" FontSize="12"/>
                    <TextBlock x:Name="ModeText" Text="UNKNOWN" FontSize="18" FontWeight="Bold" Foreground="#4DA6FF"/>
                </StackPanel>

                <StackPanel Grid.Column="2" HorizontalAlignment="Center">
                    <TextBlock Text="SEQUENCE" Foreground="#888" FontSize="12"/>
                    <TextBlock x:Name="SeqText" Text="-" FontSize="18" FontWeight="Bold" Foreground="White"/>
                </StackPanel>

                <StackPanel Grid.Column="3" HorizontalAlignment="Center">
                    <TextBlock Text="USERS" Foreground="#888" FontSize="12"/>
                    <TextBlock x:Name="UsersText" Text="0" FontSize="18" FontWeight="Bold" Foreground="#F1C40F"/>
                </StackPanel>
            </Grid>
        </Border>

        <!-- Controls -->
        <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,0,0,20">
            <Button x:Name="BtnStart" Content="START SIGNAL" Padding="20,10" Margin="10" 
                    Background="#2ECC71" Foreground="White" FontWeight="Bold" BorderThickness="0"
                    Click="BtnStart_Click"/>
            
            <Button x:Name="BtnStop" Content="STOP SIGNAL" Padding="20,10" Margin="10" 
                    Background="#E74C3C" Foreground="White" FontWeight="Bold" BorderThickness="0"
                    Click="BtnStop_Click"/>

            <CheckBox x:Name="ChkSimUser" Content="Simulate User" VerticalAlignment="Center" 
                      Foreground="White" Margin="20,0,0,0" Checked="ChkSimUser_Changed" Unchecked="ChkSimUser_Changed"/>
        </StackPanel>

        <!-- Logs -->
        <Border Grid.Row="3" Background="Black" CornerRadius="5" BorderBrush="#444" BorderThickness="1">
            <ScrollViewer x:Name="LogScroll">
                <TextBlock x:Name="LogText" FontFamily="Consolas" FontSize="12" Foreground="#CCC" Padding="10" TextWrapping="Wrap"/>
            </ScrollViewer>
        </Border>
    </Grid>
</Window>

```

---

## `Baliza_Gerard/BeaconGui/MainWindow.xaml.cs`

```csharp
﻿using System;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Media;
using System.Windows.Threading;
using Windows.Devices.Bluetooth;
using Windows.Devices.Bluetooth.Advertisement;
using Windows.Storage.Streams;
using Newtonsoft.Json;

namespace BeaconGui
{
    public partial class MainWindow : Window
    {
        // Configurable Constants
        private const string API_URL = "https://alpo.myqnapcloud.com:4010/api/state";
        private const ushort MANUFACTURER_ID = 0x1234; 
        private const int POLL_INTERVAL_MS = 2000;
        private const ushort ZONE_ID = 1001;

        // State Tracking
        private HttpClient client;
        private BluetoothLEAdvertisementPublisher publisher;
        private BluetoothLEAdvertisementWatcher watcher;
        private System.Collections.Generic.Dictionary<int, DateTime> detectedUsers = new System.Collections.Generic.Dictionary<int, DateTime>();
        private DispatcherTimer cleanupTimer;
        private ushort sequenceConfig = 0;
        private byte currentMode = 0; 
        private string lastKnownTemp = "";
        private bool isRunning = false;
        private bool simulateUser = false;

        public MainWindow()
        {
            InitializeComponent();
            SetupHttpClient();
            InitializeBeaconSystem();
        }

        private void SetupHttpClient()
        {
            var handler = new HttpClientHandler();
            handler.ClientCertificateOptions = ClientCertificateOption.Manual;
            handler.ServerCertificateCustomValidationCallback = 
                (httpRequestMessage, cert, cetChain, policyErrors) => true;
            client = new HttpClient(handler);
        }

        private async void InitializeBeaconSystem()
        {
            Log("Initializing System...");
            
            // Get MAC
            try {
                var adapter = await BluetoothAdapter.GetDefaultAsync();
                if (adapter != null) {
                    var addr = adapter.BluetoothAddress;
                    string mac = string.Join(":", BitConverter.GetBytes(addr).Reverse().Skip(2).Select(b => b.ToString("X2")));
                    Log($"My MAC Address: {mac}");
                } else {
                    Log("MAC: UNKNOWN (No Adapter)");
                }
            } catch (Exception ex) {
                Log($"Error getting MAC: {ex.Message}");
            }

            publisher = new BluetoothLEAdvertisementPublisher();
            publisher.StatusChanged += Publisher_StatusChanged;
            
            // Start Scanner for User Beacons
            watcher = new BluetoothLEAdvertisementWatcher();

            // Explicitly filter for our ID to improve reliability
            var manufacturerData = new BluetoothLEManufacturerData();
            manufacturerData.CompanyId = MANUFACTURER_ID;
            watcher.AdvertisementFilter.Advertisement.ManufacturerData.Add(manufacturerData);

            watcher.ScanningMode = BluetoothLEScanningMode.Active;
            watcher.Received += Watcher_Received;
            watcher.Start();
            Log("Scanner Started (Listening for Users)...");

            // Cleanup Timer
            cleanupTimer = new DispatcherTimer();
            cleanupTimer.Interval = TimeSpan.FromSeconds(5);
            cleanupTimer.Tick += CleanupUsers_Tick;
            cleanupTimer.Start();
            
            // Start Polling Loop in background
            _ = Task.Run(PollApiLoop);
        }

        private void Watcher_Received(BluetoothLEAdvertisementWatcher sender, BluetoothLEAdvertisementReceivedEventArgs args)
        {
            foreach (var section in args.Advertisement.ManufacturerData)
            {
                var reader = DataReader.FromBuffer(section.Data);
                byte[] bytes = new byte[section.Data.Length];
                reader.ReadBytes(bytes);
                string hex = BitConverter.ToString(bytes);

                if (section.CompanyId == MANUFACTURER_ID)
                {
                    if (bytes.Length >= 5 && bytes[0] == 0x01)
                    {
                        int hash = BitConverter.ToInt32(bytes, 1);
                        Dispatcher.Invoke(() => {
                            bool isNew = !detectedUsers.ContainsKey(hash);
                            detectedUsers[hash] = DateTime.Now;

                            if (isNew)
                            {
                                UsersText.Text = detectedUsers.Count.ToString();
                                Log($"[USER FOUND] {hash:X} ({args.RawSignalStrengthInDBm}dBm)"); 
                            }
                        });
                    }
                }
            }
        }

        private void CleanupUsers_Tick(object sender, EventArgs e)
        {
             var now = DateTime.Now;
             var stale = detectedUsers.Where(kvp => (now - kvp.Value).TotalSeconds > 30).ToList();
             
             if (stale.Any())
             {
                 foreach (var user in stale)
                 {
                     detectedUsers.Remove(user.Key);
                     Log($"[USER LOST] {user.Key:X}");
                 }
                 UsersText.Text = detectedUsers.Count.ToString();
             }
        }

        // --- BUTTON HANDLERS ---

        private async void BtnStart_Click(object sender, RoutedEventArgs e)
        {
            try 
            {
                if (isRunning) return;
                Log("Starting Signal...");
                
                // key fix: Initialize payload BEFORE starting
                await UpdateAdvertisingAsync(currentMode);
                
                // publisher.Start() called inside UpdateAdvertising usually, 
                // but UpdateAdvertising logic stops/clears/adds/STARTS.
                // So checking UpdateAdvertising implementation...
                // It does call Start(). So we don't need to call it here again explicitly 
                // OR we can just set isRunning = true first.
                
                // Let's rely on UpdateAdvertising to do the mechanics, but we need to set isRunning first
                // so the loop keeps it alive? No, the loop uses isRunning to decide whether to update.
                // But UpdateAdvertising is what puts the data in.
                
                // Let's modify UpdateAdvertising to be safer or call it here.
                
                isRunning = true; 
                UpdateStatusUI(true);
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Crash Error: {ex.Message}\nStack: {ex.StackTrace}", "Error de Inicio");
                Log($"CRITICAL START ERROR: {ex.Message}");
                isRunning = false;
                UpdateStatusUI(false);
            }
        }

        private void BtnStop_Click(object sender, RoutedEventArgs e)
        {
            if (!isRunning) return;
            Log("Stopping Signal...");
            publisher.Stop();
            isRunning = false;
            UpdateStatusUI(false);
        }

        private async void ChkSimUser_Changed(object sender, RoutedEventArgs e)
        {
             if (sender is System.Windows.Controls.CheckBox chk) 
             {
                 simulateUser = chk.IsChecked ?? false;
                 Log($"Simulation Mode: {simulateUser}");
                 if (isRunning) await UpdateAdvertisingAsync(currentMode);
             }
        }

        // --- CORE LOGIC ---

        private async Task PollApiLoop()
        {
            while (true)
            {
                if (!isRunning)
                {
                    await Task.Delay(1000);
                    continue;
                }

                try
                {
                    var json = await client.GetStringAsync(API_URL);
                    var state = JsonConvert.DeserializeObject<CircuitStateDto>(json);
                    
                    if (state != null)
                    {
                        var newMode = MapModeToByte(state.global_mode ?? state.mode);
                        var newTemp = state.temperature;

                        // UI Update
                        Dispatcher.Invoke(() => {
                            ModeText.Text = (state.global_mode ?? "NORMAL").ToUpper();
                            ModeText.Foreground = GetColorForMode(newMode);
                        });

                        // Only Update if Changed
                        if (newMode != currentMode || newTemp != lastKnownTemp || !isRunning)
                        {
                             lastKnownTemp = newTemp;
                             currentMode = newMode;
                             await UpdateAdvertisingAsync(newMode);
                             Log($"Context Changed -> Mode: {newMode}, Temp: {lastKnownTemp}");
                        }
                        else 
                        {
                             // Heartbeat log only
                             Dispatcher.Invoke(() => SeqText.Text = $"{sequenceConfig} (Hold)");
                        }
                    }
                }
                catch (Exception ex)
                {
                    Log($"API Error: {ex.Message}");
                }

                await Task.Delay(POLL_INTERVAL_MS);
            }
        }

        private async Task UpdateAdvertisingAsync(byte mode)
        {
            sequenceConfig++; 
            var writer = new DataWriter();

            if (simulateUser)
            {
                // Fake User Packet [Type(1) | Hash(4) | Lat(4) | Lon(4)]
                writer.WriteByte(0x01);
                writer.WriteInt32(unchecked((int)0xDEADBEEF));
                // Coordinates near Barcelona Circuit
                writer.WriteSingle(41.5700f); 
                writer.WriteSingle(2.2611f);
                if (sequenceConfig % 10 == 0) Log("Sim User at 41.57, 2.26");
            }
            else
            {
                // Normal Circuit Packet
                byte ttl = 10;
                byte flags = 0x00;
                byte tempByte = 0;
                if (!string.IsNullOrEmpty(lastKnownTemp))
                {
                     var digits = new string(lastKnownTemp.Where(char.IsDigit).ToArray());
                     if (byte.TryParse(digits, out byte t)) tempByte = t;
                }

                writer.WriteByte(0x01); // Version
                writer.WriteUInt16(ZONE_ID);
                writer.WriteByte(mode);
                writer.WriteByte(flags);
                writer.WriteUInt16(sequenceConfig);
                writer.WriteByte(ttl);
                writer.WriteByte(tempByte);
            }

            var buffer = writer.DetachBuffer();
            var manufacturerData = new BluetoothLEManufacturerData(MANUFACTURER_ID, buffer);

            // 1. Stop (UI Thread)
            await Dispatcher.InvokeAsync(() => {
                try { publisher.Stop(); } catch {}
            });

            // 2. Wait for stack to clear
            await Task.Delay(500);

            // 3. Start (UI Thread)
            await Dispatcher.InvokeAsync(() => {
                try {
                    publisher.Advertisement.ManufacturerData.Clear();
                    publisher.Advertisement.ManufacturerData.Add(manufacturerData);
                    
                    // Removed Name to prevent "Value does not fall within range" error
                    // publisher.Advertisement.LocalName = "GEORACING";
                    
                    publisher.Start();
                    SeqText.Text = sequenceConfig.ToString();
                } catch (Exception ex) {
                    Log($"Broadcast Error: {ex.Message}");
                }
            });
        }

        private void Publisher_StatusChanged(BluetoothLEAdvertisementPublisher sender, BluetoothLEAdvertisementPublisherStatusChangedEventArgs args)
        {
            Dispatcher.Invoke(() => {
                Log($"BLE Status: {args.Status}");
                if (args.Error != BluetoothError.Success)
                {
                    Log($"BLE CLICK ERROR: {args.Error}");
                }
            });
        }

        // --- HELPERS ---

        private void UpdateStatusUI(bool active)
        {
            if (active) {
                StatusText.Text = "BROADCASTING";
                StatusText.Foreground = new SolidColorBrush(Color.FromRgb(46, 204, 113)); // Green
            } else {
                StatusText.Text = "STOPPED";
                StatusText.Foreground = new SolidColorBrush(Color.FromRgb(231, 76, 60)); // Red
                ModeText.Text = "-";
                SeqText.Text = "-";
            }
        }

        private void Log(string msg)
        {
            Dispatcher.Invoke(() => {
                LogText.Text += $"[{DateTime.Now:HH:mm:ss}] {msg}\n";
                LogScroll.ScrollToEnd();
            });
        }

        private byte MapModeToByte(string modeString)
        {
            if (string.IsNullOrEmpty(modeString)) return 0;
            return modeString.ToUpper() switch
            {
                "NORMAL" => 0,
                "SAFETY_CAR" => 1,
                "RED_FLAG" => 2,
                "EVACUATION" => 3,
                _ => 0
            };
        }

         private Brush GetColorForMode(byte mode)
        {
            return mode switch {
                1 => Brushes.Orange,   // SC
                2 => Brushes.Red,      // Red Flag
                3 => Brushes.Magenta,  // Evacuation
                _ => Brushes.LightBlue // Normal
            };
        }
    }

    class CircuitStateDto
    {
        public string id { get; set; }
        public string global_mode { get; set; }
        public string mode { get; set; } 
        public string message { get; set; }
        public string temperature { get; set; } 
    }
}
```

---

## `Baliza_Gerard/Program.cs`

```csharp
using System;
using System.Net.Http;
using System.Runtime.InteropServices.WindowsRuntime;
using System.Text;
using System.Threading.Tasks;
using System.Linq; // Added for MAC formatting
using Windows.Devices.Bluetooth;
using Windows.Devices.Bluetooth.Advertisement;
using Windows.Storage.Streams;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace BeaconActivePc
{
    class Program
    {
        // Configurable Constants
        private const string API_URL = "https://alpo.myqnapcloud.com:4010/api/state";
        private const ushort MANUFACTURER_ID = 0x1234; // Test ID (Replace if you have a real one)
        private const int POLL_INTERVAL_MS = 2000;
        private const ushort ZONE_ID = 1001; // Example Zone ID for this PC Beacon

        // State Tracking
        private static HttpClient client;
        private static BluetoothLEAdvertisementPublisher publisher;
        private static ushort sequenceConfig = 0;
        private static byte currentMode = 0; // 0=NORMAL
        private static string lastKnownTemp = "";
        
        static async Task Main(string[] args)
        {
            // Initialize insecure HTTP client
            var handler = new HttpClientHandler();
            handler.ClientCertificateOptions = ClientCertificateOption.Manual;
            handler.ServerCertificateCustomValidationCallback = 
                (httpRequestMessage, cert, cetChain, policyErrors) =>
            {
                return true;
            };
            client = new HttpClient(handler);

            Console.WriteLine("=== GeoRacing Active Beacon (PC) ===");
            
            // PRINT ADAPTER ADDRESS
            try {
                var adapter = await BluetoothAdapter.GetDefaultAsync();
                if (adapter != null) {
                    var addr = adapter.BluetoothAddress;
                    // Format as XX:XX:XX:XX:XX:XX
                    string mac = string.Join(":", BitConverter.GetBytes(addr).Reverse().Skip(2).Select(b => b.ToString("X2")));
                    Console.WriteLine($"My MAC Address: {mac}");
                    Console.WriteLine($"Radio Info: {adapter.DeviceId}");
                } else {
                    Console.WriteLine("My MAC Address: UNKNOWN (Adapter not found)");
                }
            } catch (Exception ex) {
                 Console.WriteLine($"Could not get MAC: {ex.Message}");
            }

            Console.WriteLine($"API: {API_URL}");
            Console.WriteLine($"Zone: {ZONE_ID}");
            Console.WriteLine("Initializing BLE Publisher...");

            try
            {
                publisher = new BluetoothLEAdvertisementPublisher();
                publisher.StatusChanged += Publisher_StatusChanged;

                // Start Polling Loop
                _ = Task.Run(PollApiLoop);

                Console.WriteLine("Press any key to exit...");
                Console.ReadKey();
                publisher.Stop();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error: {ex.Message}");
            }
        }

        private static void Publisher_StatusChanged(BluetoothLEAdvertisementPublisher sender, BluetoothLEAdvertisementPublisherStatusChangedEventArgs args)
        {
            Console.WriteLine($"BLE Status: {args.Status} (Error: {args.Error})");
        }

        private static async Task PollApiLoop()
        {
            while (true)
            {
                try
                {
                    // 1. Fetch State
                    var json = await client.GetStringAsync(API_URL);
                    var state = JsonConvert.DeserializeObject<CircuitStateDto>(json);
                    
                    if (state != null)
                    {
                        var newMode = MapModeToByte(state.global_mode ?? state.mode);
                        lastKnownTemp = state.temperature;
                        
                        // 2. Update Payload if changed or refresh TTL
                        UpdateAdvertising(newMode);
                        
                        Console.WriteLine($"[{DateTime.Now:HH:mm:ss}] API OK. Mode: {state.global_mode} -> {newMode}. Seq: {sequenceConfig}");
                    }
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"[{DateTime.Now:HH:mm:ss}] API Error: {ex.Message}");
                    // Keep broadcasting last known state (Active Beacon reliability)
                    // Or switch to DEGRADED/UNKNOWN if too long? For now, keep last state logic.
                }

                await Task.Delay(POLL_INTERVAL_MS);
            }
        }

        private static void UpdateAdvertising(byte mode)
        {
            // Payload Structure (9 Bytes)
            // 0: Version (0x01)
            // 1-2: Zone ID
            // 3: Mode
            // 4: Flags
            // 5-6: Seq
            // 7: TTL (Seconds)
            // 8: Temperature (Int8)

            sequenceConfig++; 
            byte ttl = 10; // 10 seconds validity
            byte flags = 0x00; // No flags for now
            
            // Parse temperature from global var or pass it in
            // For now let's modify method signature or use a static
            byte tempByte = 0;
            if (!string.IsNullOrEmpty(lastKnownTemp))
            {
                 // Remove non-numeric
                 var digits = new string(lastKnownTemp.Where(char.IsDigit).ToArray());
                 if (byte.TryParse(digits, out byte t)) tempByte = t;
            }

            var writer = new DataWriter();
            writer.WriteByte(0x01); // Version
            writer.WriteUInt16(ZONE_ID); // Zone
            writer.WriteByte(mode); // Mode
            writer.WriteByte(flags); // Flags
            writer.WriteUInt16(sequenceConfig); // Seq
            writer.WriteByte(ttl); // TTL
            writer.WriteByte(tempByte); // Temperature

            var buffer = writer.DetachBuffer();
            
            // Re-create manufacturer data to ensure update
            var manufacturerData = new BluetoothLEManufacturerData(MANUFACTURER_ID, buffer);

            // Update Publisher
            // Note: Optimally we only change if data changed, but Seq changes every time to prove liveness.
            publisher.Stop();
            publisher.Advertisement.ManufacturerData.Clear();
            publisher.Advertisement.ManufacturerData.Add(manufacturerData);
            publisher.Start();
        }

        private static byte MapModeToByte(string modeString)
        {
            if (string.IsNullOrEmpty(modeString)) return 0; // Normal default
            
            return modeString.ToUpper() switch
            {
                "NORMAL" => 0,
                "SAFETY_CAR" => 1, // Or CONGESTION mapping
                "RED_FLAG" => 2,
                "EVACUATION" => 3,
                _ => 0
            };
        }
    }

    // DTO matching API JSON
    class CircuitStateDto
    {
        public string id { get; set; }
        public string global_mode { get; set; }
        public string mode { get; set; } // Legacy or local
        public string message { get; set; }
        public string temperature { get; set; } // New field
    }
}

```

