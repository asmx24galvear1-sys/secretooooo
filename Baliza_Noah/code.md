# Baliza_Noah — Todo el Código Fuente

Este archivo contiene todos los archivos de código fuente de la carpeta `Baliza_Noah/` concatenados.

---

## `Baliza_Noah/BeaconApp/App.xaml`

```xml
<Application x:Class="BeaconApp.App"
             xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
             xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
             StartupUri="MainWindow.xaml">
    <Application.Resources>
         
    </Application.Resources>
</Application>

```

---

## `Baliza_Noah/BeaconApp/App.xaml.cs`

```csharp
using System;
using System.Windows;

namespace BeaconApp
{
    /// <summary>
    /// Clase principal de la aplicación
    /// </summary>
    public partial class App : Application
    {
        protected override void OnStartup(StartupEventArgs e)
        {
            base.OnStartup(e);

            // Manejar excepciones no controladas
            AppDomain.CurrentDomain.UnhandledException += OnUnhandledException;
            DispatcherUnhandledException += OnDispatcherUnhandledException;

            Console.WriteLine("========================================");
            Console.WriteLine("GeoRacing - Sistema de Baliza");
            Console.WriteLine($"Iniciado: {DateTime.Now:yyyy-MM-dd HH:mm:ss}");
            Console.WriteLine("========================================");
        }

        private void OnUnhandledException(object sender, UnhandledExceptionEventArgs e)
        {
            var ex = e.ExceptionObject as Exception;
            Console.Error.WriteLine($"[FATAL] Excepción no controlada: {ex?.Message}");
            Console.Error.WriteLine(ex?.StackTrace);

            MessageBox.Show(
                $"Error crítico:\n\n{ex?.Message}\n\nLa aplicación se cerrará.",
                "Error Fatal",
                MessageBoxButton.OK,
                MessageBoxImage.Error
            );
        }

        private void OnDispatcherUnhandledException(object sender, System.Windows.Threading.DispatcherUnhandledExceptionEventArgs e)
        {
            Console.Error.WriteLine($"[ERROR] Excepción en UI: {e.Exception.Message}");
            Console.Error.WriteLine(e.Exception.StackTrace);

            MessageBox.Show(
                $"Error en la interfaz:\n\n{e.Exception.Message}",
                "Error",
                MessageBoxButton.OK,
                MessageBoxImage.Error
            );

            e.Handled = true;
        }

        protected override void OnExit(ExitEventArgs e)
        {
            Console.WriteLine("[App] Aplicación cerrada");
            base.OnExit(e);
        }
    }
}

```

---

## `Baliza_Noah/BeaconApp/BeaconApp.csproj`

```xml
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net8.0-windows10.0.19041.0</TargetFramework>
    <UseWPF>true</UseWPF>
    <UseWindowsForms>true</UseWindowsForms>
    <Nullable>enable</Nullable>
    <AssemblyName>GeoRacingBeacon</AssemblyName>
    <RootNamespace>BeaconApp</RootNamespace>
    <DefaultItemExcludes>$(DefaultItemExcludes);obj\**;bin\**;obj_new\**;bin_new\**;obj_v2\**;bin_v2\**;bin_old\**;obj_final\**;bin_final\**;obj_v3\**;bin_v3\**</DefaultItemExcludes>
  </PropertyGroup>

</Project>

```

---

## `Baliza_Noah/BeaconApp/Config/BeaconConfigService.cs`

```csharp
using System;
using System.IO;
using System.Text.Json;

namespace BeaconApp.Config
{
    /// <summary>
    /// Configuración de la baliza cargada desde beacon.json
    /// </summary>
    public record BeaconConfig(
        string BeaconId, 
        string ApiBaseUrl,
        string Name,
        string Description,
        int ZoneId,
        double Latitude,
        double Longitude
    );

    /// <summary>
    /// Servicio para leer/crear la configuración local de la baliza
    /// </summary>
    public static class BeaconConfigService
    {
        private const string CONFIG_DIR = @"C:\ProgramData\GeoRacing";
        private const string CONFIG_FILE = "beacon.json";
        private static readonly string CONFIG_PATH = Path.Combine(CONFIG_DIR, CONFIG_FILE);

        /// <summary>
        /// Lee o crea la configuración de la baliza
        /// </summary>
        public static BeaconConfig ReadOrCreateConfig()
        {
            try
            {
                // Intentar leer el archivo existente
                if (File.Exists(CONFIG_PATH))
                {
                    var json = File.ReadAllText(CONFIG_PATH);
                    var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };
                    var configJson = JsonSerializer.Deserialize<ConfigJson>(json, options);

                    if (configJson != null && 
                        !string.IsNullOrWhiteSpace(configJson.beaconId) &&
                        !string.IsNullOrWhiteSpace(configJson.apiBaseUrl))
                    {
                        Log($"✓ Configuración cargada: {configJson.beaconId}");

                        // AUTO-UPDATE: Si es la URL vieja, actualizar a la nueva HTTPS
                        if (configJson.apiBaseUrl == "http://192.168.1.99:4000")
                        {
                            Log("⚠ Detectada configuración antigua. Actualizando a HTTPS...");
                            configJson.apiBaseUrl = "https://alpo.myqnapcloud.com:4010/api/";
                            
                            // Guardar cambios
                            SaveConfig(configJson);
                            Log($"✓ Configuración actualizada a: {configJson.apiBaseUrl}");
                        }

                        return new BeaconConfig(
                            configJson.beaconId, 
                            configJson.apiBaseUrl,
                            configJson.name ?? "Baliza Sin Nombre",
                            configJson.description ?? "Sin descripción",
                            configJson.zoneId,
                            configJson.latitude,
                            configJson.longitude
                        );
                    }

                    Log("⚠ Archivo de configuración corrupto, regenerando...");
                    BackupCorruptedFile();
                }

                // Crear configuración por defecto
                return CreateDefaultConfig();
            }
            catch (Exception ex)
            {
                Log($"✗ Error al leer config: {ex.Message}");
                
                try
                {
                    BackupCorruptedFile();
                    return CreateDefaultConfig();
                }
                catch (Exception ex2)
                {
                    Log($"✗ Error crítico: {ex2.Message}");
                    throw;
                }
            }
        }

        private static BeaconConfig CreateDefaultConfig()
        {
            // Crear directorio si no existe
            if (!Directory.Exists(CONFIG_DIR))
            {
                Directory.CreateDirectory(CONFIG_DIR);
                Log($"✓ Directorio creado: {CONFIG_DIR}");
            }

            // Generar valores por defecto
            var beaconId = Environment.MachineName.Trim();
            var apiBaseUrl = "https://alpo.myqnapcloud.com:4010/api/";

            var configJson = new ConfigJson
            {
                beaconId = beaconId,
                apiBaseUrl = apiBaseUrl,
                name = beaconId,
                description = "Baliza autogenerada",
                zoneId = 1,
                latitude = 41.57,
                longitude = 2.26
            };

            // Guardar a disco
            SaveConfig(configJson);

            Log($"✓ Configuración creada: {beaconId} → {apiBaseUrl}");

            return new BeaconConfig(
                configJson.beaconId, 
                configJson.apiBaseUrl,
                configJson.name,
                configJson.description,
                configJson.zoneId,
                configJson.latitude,
                configJson.longitude
            );
        }

        private static void SaveConfig(ConfigJson config)
        {
            var options = new JsonSerializerOptions { WriteIndented = true };
            var json = JsonSerializer.Serialize(config, options);
            File.WriteAllText(CONFIG_PATH, json);
        }

        private static void BackupCorruptedFile()
        {
            if (File.Exists(CONFIG_PATH))
            {
                var timestamp = DateTime.Now.ToString("yyyyMMdd-HHmmss");
                var backupPath = Path.Combine(CONFIG_DIR, $"beacon.json.bak-{timestamp}");
                
                try
                {
                    File.Copy(CONFIG_PATH, backupPath, true);
                    File.Delete(CONFIG_PATH);
                    Log($"✓ Backup creado: {backupPath}");
                }
                catch (Exception ex)
                {
                    Log($"⚠ No se pudo crear backup: {ex.Message}");
                }
            }
        }

        private static void Log(string message)
        {
            var timestamp = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
            var logMessage = $"{timestamp} [CONFIG] {message}";
            Console.WriteLine(logMessage);

            try
            {
                var logPath = Path.Combine(CONFIG_DIR, "beacon-debug.log");
                File.AppendAllText(logPath, logMessage + Environment.NewLine);
            }
            catch
            {
                // Ignorar errores de logging
            }
        }

        // Clase interna para serialización JSON (camelCase)
        private class ConfigJson
        {
            public string beaconId { get; set; } = string.Empty;
            public string apiBaseUrl { get; set; } = string.Empty;
            public string? name { get; set; }
            public string? description { get; set; }
            public int zoneId { get; set; }
            public double latitude { get; set; }
            public double longitude { get; set; }
        }
    }
}

```

---

## `Baliza_Noah/BeaconApp/MainWindow.xaml`

```xml
<Window x:Class="BeaconApp.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:viewModels="clr-namespace:BeaconApp.ViewModels"
        mc:Ignorable="d"
        Title="GeoRacing Beacon"
        WindowStyle="None"
        WindowState="Maximized"
        ResizeMode="NoResize"
        Topmost="True"
        Background="Black"
        KeyDown="Window_KeyDown">

    <Window.Resources>
        <!-- ============================================================
             RACING TECH RESOURCES
             ============================================================ -->
        
        <!-- COLORS -->
        <Color x:Key="CircuitRed">#E30613</Color>
        <Color x:Key="RacingGreen">#00D26A</Color>
        <Color x:Key="SafetyYellow">#FFED00</Color>
        <Color x:Key="TechCyan">#00AEEF</Color>
        <Color x:Key="CarbonBlack">#111111</Color>
        
        <SolidColorBrush x:Key="BrushRed" Color="{StaticResource CircuitRed}"/>
        <SolidColorBrush x:Key="BrushGreen" Color="{StaticResource RacingGreen}"/>
        <SolidColorBrush x:Key="BrushYellow" Color="{StaticResource SafetyYellow}"/>
        <SolidColorBrush x:Key="BrushCyan" Color="{StaticResource TechCyan}"/>
        <SolidColorBrush x:Key="BrushCarbon" Color="{StaticResource CarbonBlack}"/>

        <!-- CARBON FIBER PATTERN -->
        <DrawingBrush x:Key="CarbonFiberPattern" TileMode="Tile" Viewport="0,0,20,20" ViewportUnits="Absolute">
            <DrawingBrush.Drawing>
                <GeometryDrawing Brush="#1A1A1A">
                    <GeometryDrawing.Geometry>
                        <GeometryGroup>
                            <RectangleGeometry Rect="0,0,20,20" />
                            <RectangleGeometry Rect="0,0,10,10" />
                            <RectangleGeometry Rect="10,10,10,10" />
                        </GeometryGroup>
                    </GeometryDrawing.Geometry>
                </GeometryDrawing>
            </DrawingBrush.Drawing>
        </DrawingBrush>

        <!-- SCANLINES -->
        <DrawingBrush x:Key="ScanlinesPattern" TileMode="Tile" Viewport="0,0,10,4" ViewportUnits="Absolute">
            <DrawingBrush.Drawing>
                <GeometryDrawing Brush="#22FFFFFF">
                    <GeometryDrawing.Geometry>
                        <RectangleGeometry Rect="0,0,10,1"/>
                    </GeometryDrawing.Geometry>
                </GeometryDrawing>
            </DrawingBrush.Drawing>
        </DrawingBrush>

        <!-- STYLES -->
        <Style x:Key="RacingHeader" TargetType="TextBlock">
            <Setter Property="FontFamily" Value="Impact"/>
            <Setter Property="FontSize" Value="40"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="Effect">
                <Setter.Value>
                    <DropShadowEffect Color="Black" BlurRadius="5" ShadowDepth="3"/>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="HudText" TargetType="TextBlock">
            <Setter Property="FontFamily" Value="Consolas"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Foreground" Value="{StaticResource BrushCyan}"/>
        </Style>

        <!-- DYNAMIC ARROW PATH STYLE -->
        <Style x:Key="ArrowPathStyle" TargetType="Path">
            <Setter Property="Fill" Value="{Binding Foreground, RelativeSource={RelativeSource AncestorType=ContentControl}}"/>
            <Setter Property="Stretch" Value="Uniform"/>
            <Setter Property="RenderTransformOrigin" Value="0.5,0.5"/>
            <Setter Property="Width" Value="300"/>
            <Setter Property="Height" Value="300"/>
            <!-- Default Geometry: UP ARROW -->
            <Setter Property="Data" Value="M12,2 L12,22 M2,12 L12,2 L22,12"/> 
            <!-- Better Thick Arrow Geometry (Pointing UP by default) -->
            <Setter Property="Data" Value="M 25,0 L 50,40 L 35,40 L 35,100 L 15,100 L 15,40 L 0,40 Z"/>
            
            <Setter Property="RenderTransform">
                <Setter.Value>
                    <RotateTransform Angle="0"/>
                </Setter.Value>
            </Setter>
            
            <Style.Triggers>
                <!-- DIRECTIONS -->
                <!-- UP / FORWARD (0 degrees) -->
                <DataTrigger Binding="{Binding CurrentArrow}" Value="FORWARD"><Setter Property="RenderTransform"><Setter.Value><RotateTransform Angle="0"/></Setter.Value></Setter></DataTrigger>
                <DataTrigger Binding="{Binding CurrentArrow}" Value="UP"><Setter Property="RenderTransform"><Setter.Value><RotateTransform Angle="0"/></Setter.Value></Setter></DataTrigger>
                
                <!-- DOWN / BACKWARD (180 degrees) -->
                <DataTrigger Binding="{Binding CurrentArrow}" Value="BACKWARD"><Setter Property="RenderTransform"><Setter.Value><RotateTransform Angle="180"/></Setter.Value></Setter></DataTrigger>
                <DataTrigger Binding="{Binding CurrentArrow}" Value="DOWN"><Setter Property="RenderTransform"><Setter.Value><RotateTransform Angle="180"/></Setter.Value></Setter></DataTrigger>
                
                <!-- LEFT ( -90 degrees ) -->
                <DataTrigger Binding="{Binding CurrentArrow}" Value="LEFT"><Setter Property="RenderTransform"><Setter.Value><RotateTransform Angle="-90"/></Setter.Value></Setter></DataTrigger>
                
                <!-- RIGHT ( 90 degrees ) -->
                <DataTrigger Binding="{Binding CurrentArrow}" Value="RIGHT"><Setter Property="RenderTransform"><Setter.Value><RotateTransform Angle="90"/></Setter.Value></Setter></DataTrigger>
                
                <!-- DIAGONALS -->
                <DataTrigger Binding="{Binding CurrentArrow}" Value="FORWARD_LEFT"><Setter Property="RenderTransform"><Setter.Value><RotateTransform Angle="-45"/></Setter.Value></Setter></DataTrigger>
                <DataTrigger Binding="{Binding CurrentArrow}" Value="UP_LEFT"><Setter Property="RenderTransform"><Setter.Value><RotateTransform Angle="-45"/></Setter.Value></Setter></DataTrigger>
                
                <DataTrigger Binding="{Binding CurrentArrow}" Value="FORWARD_RIGHT"><Setter Property="RenderTransform"><Setter.Value><RotateTransform Angle="45"/></Setter.Value></Setter></DataTrigger>
                <DataTrigger Binding="{Binding CurrentArrow}" Value="UP_RIGHT"><Setter Property="RenderTransform"><Setter.Value><RotateTransform Angle="45"/></Setter.Value></Setter></DataTrigger>
                
                <DataTrigger Binding="{Binding CurrentArrow}" Value="BACKWARD_LEFT"><Setter Property="RenderTransform"><Setter.Value><RotateTransform Angle="-135"/></Setter.Value></Setter></DataTrigger>
                <DataTrigger Binding="{Binding CurrentArrow}" Value="DOWN_LEFT"><Setter Property="RenderTransform"><Setter.Value><RotateTransform Angle="-135"/></Setter.Value></Setter></DataTrigger>
                
                <DataTrigger Binding="{Binding CurrentArrow}" Value="BACKWARD_RIGHT"><Setter Property="RenderTransform"><Setter.Value><RotateTransform Angle="135"/></Setter.Value></Setter></DataTrigger>
                <DataTrigger Binding="{Binding CurrentArrow}" Value="DOWN_RIGHT"><Setter Property="RenderTransform"><Setter.Value><RotateTransform Angle="135"/></Setter.Value></Setter></DataTrigger>
            </Style.Triggers>
        </Style>

    </Window.Resources>

    <!-- MAIN CONTAINER -->
    <Grid Background="{StaticResource CarbonFiberPattern}">
        
        <!-- GLOBAL OVERLAYS -->
        <Rectangle Fill="{StaticResource ScanlinesPattern}" IsHitTestVisible="False" Opacity="0.3"/>
        
        <!-- TOP BAR (Circuit Status) -->
        <Grid VerticalAlignment="Top" Height="80" Background="#CC000000">
            <Border BorderBrush="#333" BorderThickness="0,0,0,2"/>
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Left" Margin="40,0">
                <TextBlock Text="CIRCUIT DE BARCELONA-CATALUNYA" Style="{StaticResource RacingHeader}" FontSize="24" VerticalAlignment="Center" Foreground="#AAA"/>
                <Rectangle Width="2" Height="40" Fill="#555" Margin="20,0"/>
                <TextBlock Text="{Binding CurrentZone}" Style="{StaticResource HudText}" FontSize="24" VerticalAlignment="Center" Foreground="White"/>
            </StackPanel>
            
            <!-- Clock -->
            <TextBlock x:Name="TimeTextNormal" Text="{Binding Source={x:Static sys:DateTime.Now}, StringFormat=HH:mm:ss}" 
                       xmlns:sys="clr-namespace:System;assembly=mscorlib"
                       Style="{StaticResource HudText}" FontSize="30" HorizontalAlignment="Right" VerticalAlignment="Center" Margin="40,0"/>
        </Grid>

        <!-- ============================================================
             VIEW 1: NORMAL (Green Flag)
             ============================================================ -->
        <Grid x:Name="ViewNormal">
            <Grid.Style>
                <Style TargetType="Grid">
                    <Setter Property="Visibility" Value="Collapsed"/>
                    <Style.Triggers>
                        <DataTrigger Binding="{Binding CurrentMode}" Value="NORMAL">
                            <Setter Property="Visibility" Value="Visible"/>
                        </DataTrigger>
                    </Style.Triggers>
                </Style>
            </Grid.Style>

            <!-- Center HUD -->
            <Border Width="600" Height="600" BorderBrush="{StaticResource BrushGreen}" BorderThickness="4" CornerRadius="300" HorizontalAlignment="Center" VerticalAlignment="Center" Margin="0,0,0,250">
                <Border.Effect>
                    <DropShadowEffect Color="{StaticResource RacingGreen}" BlurRadius="50" ShadowDepth="0"/>
                </Border.Effect>
                <Grid>
                    <Ellipse Stroke="{StaticResource BrushGreen}" StrokeThickness="2" Opacity="0.3" Margin="20"/>
                    <Ellipse Stroke="{StaticResource BrushGreen}" StrokeThickness="10" StrokeDashArray="1 0.5" Margin="40"/>
                    
                    <!-- Arrow -->
                    <Path Style="{StaticResource ArrowPathStyle}" Fill="{StaticResource BrushGreen}" Width="350" Height="350">
                        <Path.Effect>
                            <DropShadowEffect Color="{StaticResource RacingGreen}" BlurRadius="20" ShadowDepth="0"/>
                        </Path.Effect>
                    </Path>
                </Grid>
            </Border>

            <!-- Status Text -->
            <Border Background="#CC000000" VerticalAlignment="Bottom" Margin="0,0,0,50" HorizontalAlignment="Center" Padding="60,20" CornerRadius="10">
                <Border.RenderTransform>
                    <SkewTransform AngleX="-20"/>
                </Border.RenderTransform>
                <Border.BorderBrush>
                    <SolidColorBrush Color="{StaticResource RacingGreen}"/>
                </Border.BorderBrush>
                <Border.BorderThickness>
                    <Thickness Left="10" Right="10"/>
                </Border.BorderThickness>
                
                <TextBlock Text="{Binding DisplayText}" Style="{StaticResource RacingHeader}" FontSize="60" Foreground="{StaticResource BrushGreen}">
                    <TextBlock.RenderTransform>
                        <SkewTransform AngleX="20"/>
                    </TextBlock.RenderTransform>
                </TextBlock>
            </Border>
            
            <!-- Side Decoration -->
            <Rectangle Width="20" HorizontalAlignment="Left" Fill="{StaticResource BrushGreen}" Opacity="0.5"/>
            <Rectangle Width="20" HorizontalAlignment="Right" Fill="{StaticResource BrushGreen}" Opacity="0.5"/>
        </Grid>

        <!-- ============================================================
             VIEW 2: CONGESTION (Yellow Flag)
             ============================================================ -->
        <!-- ============================================================
             VIEW 2: CONGESTION (Yellow Flag)
             ============================================================ -->
        <Grid x:Name="ViewCongestion">
            <Grid.Style>
                <Style TargetType="Grid">
                    <Setter Property="Visibility" Value="Collapsed"/>
                    <Style.Triggers>
                        <DataTrigger Binding="{Binding CurrentMode}" Value="CONGESTION">
                            <Setter Property="Visibility" Value="Visible"/>
                        </DataTrigger>
                    </Style.Triggers>
                </Style>
            </Grid.Style>

            <!-- Stripes Background (Subtle) -->
            <Grid.Resources>
                <DrawingBrush x:Key="Stripes" TileMode="Tile" Viewport="0,0,100,100" ViewportUnits="Absolute">
                    <DrawingBrush.Drawing>
                        <GeometryDrawing Brush="#33FFED00">
                            <GeometryDrawing.Geometry>
                                <GeometryGroup>
                                    <PathGeometry Figures="M0,0 L50,0 L0,50 Z M50,50 L100,50 L100,0 Z"/>
                                </GeometryGroup>
                            </GeometryDrawing.Geometry>
                        </GeometryDrawing>
                    </DrawingBrush.Drawing>
                </DrawingBrush>
            </Grid.Resources>
            <Rectangle Fill="{StaticResource Stripes}" Opacity="0.1"/>

            <!-- Center HUD (Yellow) -->
            <Border Width="600" Height="600" BorderBrush="{StaticResource BrushYellow}" BorderThickness="4" CornerRadius="300" HorizontalAlignment="Center" VerticalAlignment="Center" Margin="0,0,0,250">
                <Border.Effect>
                    <DropShadowEffect Color="{StaticResource SafetyYellow}" BlurRadius="50" ShadowDepth="0"/>
                </Border.Effect>
                <Grid>
                    <Ellipse Stroke="{StaticResource BrushYellow}" StrokeThickness="2" Opacity="0.3" Margin="20"/>
                    <Ellipse Stroke="{StaticResource BrushYellow}" StrokeThickness="10" StrokeDashArray="1 0.5" Margin="40"/>
                    
                    <!-- Arrow -->
                    <Path Style="{StaticResource ArrowPathStyle}" Fill="{StaticResource BrushYellow}" Width="350" Height="350">
                        <Path.Effect>
                            <DropShadowEffect Color="{StaticResource SafetyYellow}" BlurRadius="20" ShadowDepth="0"/>
                        </Path.Effect>
                    </Path>

                     <!-- Warning Triangle (Overrides Arrow if Arrow is NONE or specific logic) -->
                     <!-- Logic: If Arrow is visible (non-NONE), this triangle hides automatically via Trigger if we add it? 
                          Actually ViewNormal arrow hides if NONE? No, style data triggers rotate it.
                          We need a trigger to hide Arrow if NONE. 
                          But let's assume Congestion mostly has arrows. 
                          If no arrow, show Triangle. -->
                </Grid>
            </Border>

            <!-- Status Text (Standardized Footer) -->
            <Border Background="#CC000000" VerticalAlignment="Bottom" Margin="0,0,0,50" HorizontalAlignment="Center" Padding="60,20" CornerRadius="10">
                <Border.RenderTransform>
                    <SkewTransform AngleX="-20"/>
                </Border.RenderTransform>
                <Border.BorderBrush>
                    <SolidColorBrush Color="{StaticResource SafetyYellow}"/>
                </Border.BorderBrush>
                <Border.BorderThickness>
                    <Thickness Left="10" Right="10"/>
                </Border.BorderThickness>
                
                <StackPanel>
                    <TextBlock Text="CAUTION" Style="{StaticResource RacingHeader}" FontSize="40" Foreground="{StaticResource BrushYellow}" HorizontalAlignment="Center">
                        <TextBlock.RenderTransform><SkewTransform AngleX="20"/></TextBlock.RenderTransform>
                    </TextBlock>
                    <TextBlock Text="{Binding DisplayText}" Style="{StaticResource RacingHeader}" FontSize="60" Foreground="{StaticResource BrushYellow}">
                        <TextBlock.RenderTransform><SkewTransform AngleX="20"/></TextBlock.RenderTransform>
                    </TextBlock>
                </StackPanel>
            </Border>
            
            <!-- Side Decoration -->
            <Rectangle Width="20" HorizontalAlignment="Left" Fill="{StaticResource BrushYellow}" Opacity="0.5"/>
            <Rectangle Width="20" HorizontalAlignment="Right" Fill="{StaticResource BrushYellow}" Opacity="0.5"/>
        </Grid>

        <!-- ============================================================
             VIEW 3: EMERGENCY (Red Flag)
             ============================================================ -->
        <Grid x:Name="ViewEmergency">
            <Grid.Style>
                <Style TargetType="Grid">
                    <Setter Property="Visibility" Value="Collapsed"/>
                    <Style.Triggers>
                        <DataTrigger Binding="{Binding CurrentMode}" Value="EMERGENCY">
                            <Setter Property="Visibility" Value="Visible"/>
                        </DataTrigger>
                    </Style.Triggers>
                </Style>
            </Grid.Style>

            <Rectangle Fill="#22FF0000"/>
            
            <!-- Center HUD (Red) -->
            <Border Width="600" Height="600" BorderBrush="{StaticResource BrushRed}" BorderThickness="4" CornerRadius="300" HorizontalAlignment="Center" VerticalAlignment="Center" Margin="0,0,0,250">
                <Border.Effect>
                    <DropShadowEffect Color="{StaticResource CircuitRed}" BlurRadius="50" ShadowDepth="0"/>
                </Border.Effect>
                <Grid>
                    <Ellipse Stroke="{StaticResource BrushRed}" StrokeThickness="2" Opacity="0.3" Margin="20"/>
                    <Ellipse Stroke="{StaticResource BrushRed}" StrokeThickness="10" StrokeDashArray="1 0.5" Margin="40"/>
                    
                    <!-- Arrow -->
                    <Path Style="{StaticResource ArrowPathStyle}" Fill="{StaticResource BrushRed}" Width="350" Height="350">
                        <Path.Effect>
                            <DropShadowEffect Color="{StaticResource CircuitRed}" BlurRadius="20" ShadowDepth="0"/>
                        </Path.Effect>
                    </Path>
                </Grid>
            </Border>
            
            <!-- Pulsing Border (Optional, maybe too much if wanting similarity) -->
            <!-- Removing big border to match Normal style more closely -->

            <!-- Status Text (Standardized Footer) -->
            <Border Background="#CC000000" VerticalAlignment="Bottom" Margin="0,0,0,50" HorizontalAlignment="Center" Padding="60,20" CornerRadius="10">
                <Border.RenderTransform>
                    <SkewTransform AngleX="-20"/>
                </Border.RenderTransform>
                <Border.BorderBrush>
                    <SolidColorBrush Color="{StaticResource CircuitRed}"/>
                </Border.BorderBrush>
                <Border.BorderThickness>
                    <Thickness Left="10" Right="10"/>
                </Border.BorderThickness>
                
                <StackPanel>
                    <TextBlock Text="RED FLAG" Style="{StaticResource RacingHeader}" FontSize="40" Foreground="{StaticResource BrushRed}" HorizontalAlignment="Center">
                        <TextBlock.RenderTransform><SkewTransform AngleX="20"/></TextBlock.RenderTransform>
                    </TextBlock>
                    <TextBlock Text="{Binding DisplayText}" Style="{StaticResource RacingHeader}" FontSize="60" Foreground="{StaticResource BrushRed}">
                        <TextBlock.RenderTransform><SkewTransform AngleX="20"/></TextBlock.RenderTransform>
                    </TextBlock>
                </StackPanel>
            </Border>

            <!-- Side Decoration -->
            <Rectangle Width="20" HorizontalAlignment="Left" Fill="{StaticResource BrushRed}" Opacity="0.5"/>
            <Rectangle Width="20" HorizontalAlignment="Right" Fill="{StaticResource BrushRed}" Opacity="0.5"/>
        </Grid>

        <!-- ============================================================
             VIEW 4: EVACUATION (Red Strobe)
             ============================================================ -->
        <Grid x:Name="ViewEvacuation">
            <Grid.Style>
                <Style TargetType="Grid">
                    <Setter Property="Visibility" Value="Collapsed"/>
                    <Style.Triggers>
                        <DataTrigger Binding="{Binding CurrentMode}" Value="EVACUATION">
                            <Setter Property="Visibility" Value="Visible"/>
                        </DataTrigger>
                    </Style.Triggers>
                </Style>
            </Grid.Style>

            <!-- Background Strobe/Grid -->
             <UniformGrid Rows="3" Columns="3" Opacity="0.1">
                <Path Data="M0,20 L10,0 L20,20" Stroke="Red" StrokeThickness="2" Stretch="Uniform" Margin="20"/>
                <Path Data="M0,20 L10,0 L20,20" Stroke="Red" StrokeThickness="2" Stretch="Uniform" Margin="20"/>
                <Path Data="M0,20 L10,0 L20,20" Stroke="Red" StrokeThickness="2" Stretch="Uniform" Margin="20"/>
                <Path Data="M0,20 L10,0 L20,20" Stroke="Red" StrokeThickness="2" Stretch="Uniform" Margin="20"/>
                <Path Data="M0,20 L10,0 L20,20" Stroke="Red" StrokeThickness="2" Stretch="Uniform" Margin="20"/>
                <Path Data="M0,20 L10,0 L20,20" Stroke="Red" StrokeThickness="2" Stretch="Uniform" Margin="20"/>
                <Path Data="M0,20 L10,0 L20,20" Stroke="Red" StrokeThickness="2" Stretch="Uniform" Margin="20"/>
                <Path Data="M0,20 L10,0 L20,20" Stroke="Red" StrokeThickness="2" Stretch="Uniform" Margin="20"/>
                <Path Data="M0,20 L10,0 L20,20" Stroke="Red" StrokeThickness="2" Stretch="Uniform" Margin="20"/>
            </UniformGrid>

            <!-- Center HUD (Red) -->
            <Border Width="600" Height="600" BorderBrush="{StaticResource BrushRed}" BorderThickness="4" CornerRadius="300" HorizontalAlignment="Center" VerticalAlignment="Center" Margin="0,0,0,250">
                <Border.Effect>
                    <DropShadowEffect Color="{StaticResource CircuitRed}" BlurRadius="50" ShadowDepth="0"/>
                </Border.Effect>
                <Grid>
                     <Ellipse Stroke="{StaticResource BrushRed}" StrokeThickness="2" Opacity="0.3" Margin="20"/>
                     <!-- Arrow -->
                    <Path Style="{StaticResource ArrowPathStyle}" Fill="{StaticResource BrushRed}" Width="350" Height="350">
                        <Path.Effect>
                            <DropShadowEffect Color="{StaticResource CircuitRed}" BlurRadius="20" ShadowDepth="0"/>
                        </Path.Effect>
                    </Path>
                </Grid>
            </Border>

            <!-- Status Text (Standardized Footer) -->
            <Border Background="#CC000000" VerticalAlignment="Bottom" Margin="0,0,0,50" HorizontalAlignment="Center" Padding="60,20" CornerRadius="10">
                <Border.RenderTransform>
                    <SkewTransform AngleX="-20"/>
                </Border.RenderTransform>
                <Border.BorderBrush>
                    <SolidColorBrush Color="{StaticResource CircuitRed}"/>
                </Border.BorderBrush>
                <Border.BorderThickness>
                    <Thickness Left="10" Right="10"/>
                </Border.BorderThickness>
                
                <StackPanel>
                    <TextBlock Text="EVACUATE / EVACUACIÓN" Style="{StaticResource RacingHeader}" FontSize="40" Foreground="{StaticResource BrushRed}" HorizontalAlignment="Center">
                        <TextBlock.RenderTransform><SkewTransform AngleX="20"/></TextBlock.RenderTransform>
                    </TextBlock>
                    <TextBlock Text="{Binding DisplayText}" Style="{StaticResource RacingHeader}" FontSize="60" Foreground="{StaticResource BrushRed}">
                        <TextBlock.RenderTransform><SkewTransform AngleX="20"/></TextBlock.RenderTransform>
                    </TextBlock>
                </StackPanel>
            </Border>

            <!-- Side Decoration -->
            <Rectangle Width="20" HorizontalAlignment="Left" Fill="{StaticResource BrushRed}" Opacity="0.5"/>
            <Rectangle Width="20" HorizontalAlignment="Right" Fill="{StaticResource BrushRed}" Opacity="0.5"/>
        </Grid>

        <!-- ============================================================
             VIEW 5: MAINTENANCE (Telemetry)
             ============================================================ -->
        <!-- ============================================================
             VIEW 5: MAINTENANCE (Telemetry)
             ============================================================ -->
        <Grid x:Name="ViewMaintenance">
            <Grid.Style>
                <Style TargetType="Grid">
                    <Setter Property="Visibility" Value="Collapsed"/>
                    <Style.Triggers>
                        <DataTrigger Binding="{Binding CurrentMode}" Value="MAINTENANCE">
                            <Setter Property="Visibility" Value="Visible"/>
                        </DataTrigger>
                    </Style.Triggers>
                </Style>
            </Grid.Style>

            <!-- Grid Background -->
            <Grid.Resources>
                <DrawingBrush x:Key="TechGrid" TileMode="Tile" Viewport="0,0,50,50" ViewportUnits="Absolute">
                    <DrawingBrush.Drawing>
                        <GeometryDrawing>
                            <GeometryDrawing.Geometry>
                                <GeometryGroup>
                                    <LineGeometry StartPoint="0,0" EndPoint="50,0" />
                                    <LineGeometry StartPoint="0,0" EndPoint="0,50" />
                                </GeometryGroup>
                            </GeometryDrawing.Geometry>
                            <GeometryDrawing.Pen>
                                <Pen Brush="#3300AEEF" Thickness="1" />
                            </GeometryDrawing.Pen>
                        </GeometryDrawing>
                    </DrawingBrush.Drawing>
                </DrawingBrush>
            </Grid.Resources>
            <Rectangle Fill="{StaticResource TechGrid}"/>

            <!-- Center Content (Telemetry) -->
            <!-- We don't use the Circle HUD here because text table fits better in rectangle, 
                 but we style it with the Border/Glow effect -->
            <Border BorderBrush="{StaticResource BrushCyan}" BorderThickness="4" Background="#CC000000" CornerRadius="20" HorizontalAlignment="Center" VerticalAlignment="Center" Padding="40" Margin="0,0,0,250">
                <Border.Effect>
                    <DropShadowEffect Color="{StaticResource TechCyan}" BlurRadius="30" ShadowDepth="0"/>
                </Border.Effect>
                <StackPanel>
                    <TextBlock Text="SYSTEM TELEMETRY" Style="{StaticResource RacingHeader}" FontSize="40" Foreground="{StaticResource BrushCyan}" HorizontalAlignment="Center" Margin="0,0,0,20"/>
                    
                     <UniformGrid Columns="2" Width="600">
                        <TextBlock Text="NETWORK" Style="{StaticResource HudText}" FontSize="20" Margin="10"/>
                        <TextBlock Text="ONLINE (1Gbps)" Style="{StaticResource HudText}" Foreground="White" FontSize="20" Margin="10" HorizontalAlignment="Right"/>
                        
                        <TextBlock Text="LATENCY" Style="{StaticResource HudText}" FontSize="20" Margin="10"/>
                        <TextBlock Text="12ms" Style="{StaticResource HudText}" Foreground="White" FontSize="20" Margin="10" HorizontalAlignment="Right"/>
                        
                        <TextBlock Text="GPU TEMP" Style="{StaticResource HudText}" FontSize="20" Margin="10"/>
                        <TextBlock Text="45°C" Style="{StaticResource HudText}" Foreground="White" FontSize="20" Margin="10" HorizontalAlignment="Right"/>
                        
                        <TextBlock Text="UPTIME" Style="{StaticResource HudText}" FontSize="20" Margin="10"/>
                        <TextBlock Text="04:20:11" Style="{StaticResource HudText}" Foreground="White" FontSize="20" Margin="10" HorizontalAlignment="Right"/>
                    </UniformGrid>
                </StackPanel>
            </Border>

            <!-- Status Text (Standardized Footer) -->
            <Border Background="#CC000000" VerticalAlignment="Bottom" Margin="0,0,0,50" HorizontalAlignment="Center" Padding="60,20" CornerRadius="10">
                <Border.RenderTransform>
                    <SkewTransform AngleX="-20"/>
                </Border.RenderTransform>
                <Border.BorderBrush>
                    <SolidColorBrush Color="{StaticResource TechCyan}"/>
                </Border.BorderBrush>
                <Border.BorderThickness>
                    <Thickness Left="10" Right="10"/>
                </Border.BorderThickness>
                
                <StackPanel>
                    <TextBlock Text="MAINTENANCE MODE" Style="{StaticResource RacingHeader}" FontSize="40" Foreground="{StaticResource BrushCyan}" HorizontalAlignment="Center">
                        <TextBlock.RenderTransform><SkewTransform AngleX="20"/></TextBlock.RenderTransform>
                    </TextBlock>
                    <TextBlock Text="PIT ENTRY OPEN" Style="{StaticResource RacingHeader}" FontSize="30" Foreground="White" HorizontalAlignment="Center">
                        <TextBlock.RenderTransform><SkewTransform AngleX="20"/></TextBlock.RenderTransform>
                    </TextBlock>
                </StackPanel>
            </Border>
            
            <!-- Side Decoration -->
            <Rectangle Width="20" HorizontalAlignment="Left" Fill="{StaticResource BrushCyan}" Opacity="0.5"/>
            <Rectangle Width="20" HorizontalAlignment="Right" Fill="{StaticResource BrushCyan}" Opacity="0.5"/>
        </Grid>

        <!-- HIDDEN COMMAND INPUT -->
        <StackPanel VerticalAlignment="Top" HorizontalAlignment="Left" Opacity="0" IsHitTestVisible="False" Width="1" Height="1">
            <TextBox x:Name="CommandInput" />
            <Button Content="Send" Click="SendCommandButton_Click" />
            <Button Content="Restart" Click="RestartButton_Click" />
        </StackPanel>

    </Grid>
</Window>

```

---

## `Baliza_Noah/BeaconApp/MainWindow.xaml.cs`

```csharp
using System;
using System.Windows;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Animation;
using System.Windows.Media.Effects;
using System.Windows.Threading;
using System.Diagnostics;
using System.Threading.Tasks;
using BeaconApp.Config;
using BeaconApp.Services;
using BeaconApp.ViewModels;

namespace BeaconApp
{
    /// <summary>
    /// Ventana principal de la aplicación de baliza
    /// </summary>
    public partial class MainWindow : Window
    {
        private MainViewModel? _viewModel;
        private ApiClient? _apiClient;
        private DispatcherTimer? _clockTimer;
        private DispatcherTimer? _commandTimer;
        private string _beaconId = string.Empty;
        
        public MainWindow()
        {
            InitializeComponent();
            
            Loaded += MainWindow_Loaded;
            Closing += MainWindow_Closing;
            
            // Iniciar reloj en tiempo real
            _clockTimer = new DispatcherTimer
            {
                Interval = TimeSpan.FromSeconds(1)
            };
            _clockTimer.Tick += UpdateClock;
            _clockTimer.Start();
        }

        private void MainWindow_Loaded(object sender, RoutedEventArgs e)
        {
            try
            {
                Console.WriteLine("========================================");
                Console.WriteLine("🏁 GeoRacing - Baliza");
                Console.WriteLine("========================================");

                // 1. Leer/crear configuración
                var config = BeaconConfigService.ReadOrCreateConfig();
                _beaconId = config.BeaconId;
                Console.WriteLine($"Baliza ID: {config.BeaconId}");
                Console.WriteLine($"API URL: {config.ApiBaseUrl}");

                // 2. Crear cliente API
                _apiClient = new ApiClient(config.ApiBaseUrl);

                // 3. Crear ViewModel
                _viewModel = new MainViewModel(config, _apiClient);
                DataContext = _viewModel;

                // 4. Suscribirse a cambios de color de fondo
                _viewModel.PropertyChanged += ViewModel_PropertyChanged;

                // 5. Iniciar servicios
                _ = _viewModel.Start();

                Console.WriteLine("✓ Aplicación iniciada correctamente");
                Console.WriteLine("========================================");
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine($"✗ Error al iniciar: {ex.Message}");
                Console.Error.WriteLine(ex.StackTrace);
                
                MessageBox.Show(
                    $"Error al iniciar la aplicación:\n\n{ex.Message}",
                    "Error de Inicio",
                    MessageBoxButton.OK,
                    MessageBoxImage.Error
                );
                
                Application.Current.Shutdown();
            }
        }

        private void MainWindow_Closing(object? sender, System.ComponentModel.CancelEventArgs e)
        {
            Console.WriteLine("Cerrando aplicación...");
            
            _viewModel?.Stop();
            // _apiClient?.Dispose();
            if (_commandTimer != null)
            {
                _commandTimer.Stop();
                _commandTimer = null;
            }
            
            Console.WriteLine("✓ Aplicación cerrada");
        }

        private void UpdateClock(object? sender, EventArgs e)
        {
            // Update clock in all views
            if (TimeTextNormal != null) TimeTextNormal.Text = DateTime.Now.ToString("HH:mm:ss");
            // Add other TimeText controls if needed or bind them
        }

        private void ViewModel_PropertyChanged(object? sender, System.ComponentModel.PropertyChangedEventArgs e)
        {
            // La UI se actualiza automáticamente via DataBinding en XAML
        }

        private void Window_KeyDown(object sender, KeyEventArgs e)
        {
            if (e.Key == Key.Escape)
            {
                Console.WriteLine("ESC presionado, cerrando aplicación...");
                Close();
            }
        }

        // ============================================================
        // COMANDOS DEL BACKEND → ACCIONES LOCALES
        // ============================================================
        // ============================================================
        // COMANDOS DEL BACKEND → ACCIONES LOCALES
        // ============================================================
        // La lógica de polling se ha movido al ViewModel (MainViewModel.cs)
        // para centralizar la comunicación con la API.

        private bool ExecuteSystemCommand(string command, string? value)
        {
            try
            {
                switch (command)
                {
                    case "RESTART":
                        return RunShutdown("/r /t 3"); // Reiniciar Windows (3s delay)
                    case "SHUTDOWN":
                        return RunShutdown("/s /t 3"); // Apagar Windows (3s delay)
                    case "CLOSE":
                        return RunShutdown("/s /t 3"); // Según tu nota: close apaga el PC
                    case "CLOSE_APP":
                        Application.Current.Shutdown();
                        return true;
                    default:
                        Console.WriteLine($"[CMD] No reconocido: {command}");
                        return false;
                }
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine($"✗ Error ejecutando comando {command}: {ex.Message}");
                return false;
            }
        }

        private bool RunShutdown(string args)
        {
            try
            {
                var psi = new ProcessStartInfo
                {
                    FileName = "shutdown.exe",
                    Arguments = args,
                    CreateNoWindow = true,
                    UseShellExecute = false
                };
                Process.Start(psi);
                return true;
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine($"✗ shutdown.exe fallo: {ex.Message}");
                return false;
            }
        }

        private async void SendCommandButton_Click(object sender, RoutedEventArgs e)
        {
            try
            {
                if (_apiClient == null || string.IsNullOrWhiteSpace(_beaconId)) return;

                var command = CommandInput.Text?.Trim();
                string? value = null; // Simplificado para diseño limpio

                if (string.IsNullOrWhiteSpace(command))
                {
                    Console.WriteLine("[UI] Comando vacío – no se envía");
                    return;
                }

                var ok = await _apiClient.CreateCommandAsync(_beaconId, command.ToUpperInvariant(), string.IsNullOrWhiteSpace(value) ? null : value);
                // BottomButtonText.Text = ok ? $"CMD: {command.ToUpperInvariant()}" : "ERROR CMD";
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine($"✗ Error enviando comando: {ex.Message}");
                // BottomButtonText.Text = "ERROR CMD";
            }
        }

        private async void RestartButton_Click(object sender, RoutedEventArgs e)
        {
            try
            {
                if (_apiClient == null || string.IsNullOrWhiteSpace(_beaconId)) return;
                var ok = await _apiClient.CreateCommandAsync(_beaconId, "RESTART");
                // BottomButtonText.Text = ok ? "CMD: RESTART" : "ERROR CMD";
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine($"✗ Error enviando RESTART: {ex.Message}");
                // BottomButtonText.Text = "ERROR CMD";
            }
        }
    }
}

```

---

## `Baliza_Noah/BeaconApp/Models/BeaconModels.cs`

```csharp
using System;
using System.Text.Json.Serialization;
using System.Text.Json;

namespace BeaconApp.Models
{
    /// <summary>
    /// Modelo para el payload de heartbeat (POST /api/beacons/heartbeat)
    /// </summary>
    public class BeaconHeartbeatRequest
    {
        [JsonPropertyName("beacon_uid")]
        public string BeaconUid { get; set; } = string.Empty;

        [JsonPropertyName("name")]
        public string Name { get; set; } = string.Empty;

        [JsonPropertyName("description")]
        public string Description { get; set; } = string.Empty;

        [JsonPropertyName("zone_id")]
        public int ZoneId { get; set; }

        [JsonPropertyName("latitude")]
        public double Latitude { get; set; }

        [JsonPropertyName("longitude")]
        public double Longitude { get; set; }

        [JsonPropertyName("has_screen")]
        public int HasScreen { get; set; } = 1; // 1 = true, 0 = false

        [JsonPropertyName("mode")]
        public string Mode { get; set; } = "NORMAL";

        [JsonPropertyName("arrow_direction")]
        public string ArrowDirection { get; set; } = "NONE";

        [JsonPropertyName("message")]
        public string Message { get; set; } = string.Empty;

        [JsonPropertyName("color")]
        public string Color { get; set; } = "#00FF00";

        [JsonPropertyName("brightness")]
        public int Brightness { get; set; } = 100;

        [JsonPropertyName("battery_level")]
        public int BatteryLevel { get; set; } = 100;
    }

    /// <summary>
    /// Modelo para comandos recibidos desde la API (GET /api/commands/pending/{beaconUid})
    /// </summary>
    public class BeaconCommandDto
    {
        [JsonPropertyName("id")]
        public string Id { get; set; } = string.Empty;

        [JsonPropertyName("beacon_uid")]
        public string BeaconUid { get; set; } = string.Empty;

        [JsonPropertyName("command")]
        public string Command { get; set; } = string.Empty;

        [JsonPropertyName("value")]
        public string Value { get; set; } = string.Empty;

        [JsonPropertyName("status")]
        public string Status { get; set; } = "PENDING";

        [JsonPropertyName("created_at")]
        [JsonConverter(typeof(CustomDateTimeConverter))]
        public DateTime CreatedAt { get; set; }

        [JsonPropertyName("executed_at")]
        [JsonConverter(typeof(CustomDateTimeConverter))]
        public DateTime? ExecutedAt { get; set; }
    }

    /// <summary>
    /// Modelo para deserializar el JSON de Value cuando el comando es UPDATE_CONFIG
    /// </summary>
    public class BeaconConfigUpdate
    {
        [JsonPropertyName("mode")]
        public string? Mode { get; set; }

        [JsonPropertyName("arrow")]
        public string? Arrow { get; set; }

        [JsonPropertyName("message")]
        public string? Message { get; set; }

        [JsonPropertyName("color")]
        public string? Color { get; set; }

        [JsonPropertyName("brightness")]
        public int? Brightness { get; set; }

        [JsonPropertyName("evacuation_exit")]
        public string? EvacuationExit { get; set; }

        [JsonPropertyName("zone")]
        public string? Zone { get; set; }
    }

    /// <summary>
    /// Modelo para el estado global del circuito (tabla circuit_state)
    /// </summary>
    public class CircuitState
    {
        [JsonPropertyName("global_mode")]
        public string GlobalMode { get; set; } = "NORMAL";

        [JsonPropertyName("temperature")]
        public double? Temperature { get; set; }

        [JsonPropertyName("message")]
        public string? Message { get; set; }

        [JsonPropertyName("evacuation_route")]
        public string? EvacuationRoute { get; set; }
    }

    public class CustomDateTimeConverter : JsonConverter<DateTime>
    {
        public override DateTime Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
        {
            var str = reader.GetString();
            if (string.IsNullOrEmpty(str)) return DateTime.MinValue;

            // Intentar formato con espacio (DB) usando InvariantCulture para evitar errores de locales (ej: ES vs EN)
            if (DateTime.TryParse(str, System.Globalization.CultureInfo.InvariantCulture, System.Globalization.DateTimeStyles.None, out var dt))
            {
                if (dt.Kind == DateTimeKind.Unspecified)
                {
                    return DateTime.SpecifyKind(dt, DateTimeKind.Utc);
                }
                return dt;
            }
            
            return DateTime.MinValue;
        }

        public override void Write(Utf8JsonWriter writer, DateTime value, JsonSerializerOptions options)
        {
            writer.WriteStringValue(value.ToString("yyyy-MM-dd HH:mm:ss"));
        }
    }
}

```

---

## `Baliza_Noah/BeaconApp/Services/ApiClient.cs`

```csharp
using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Net.Http.Json;
using System.Text.Json;
using System.Threading.Tasks;
using BeaconApp.Models;

namespace BeaconApp.Services
{
    /// <summary>
    /// Cliente HTTP para comunicarse con la API de GeoRacing
    /// </summary>
    public class ApiClient
    {
        private readonly HttpClient _httpClient;
        private readonly string _baseUrl;

        public ApiClient(string baseUrl)
        {
            // Asegurar que termine en / para que HttpClient resuelva bien las rutas relativas
            _baseUrl = baseUrl.TrimEnd('/') + "/";
            
            // Permitir certificados autosignados (HTTPS)
            var handler = new HttpClientHandler
            {
                ServerCertificateCustomValidationCallback = (message, cert, chain, errors) => true
            };

            _httpClient = new HttpClient(handler)
            {
                BaseAddress = new Uri(_baseUrl),
                Timeout = TimeSpan.FromSeconds(10)
            };

            Log($"Cliente API inicializado: {_baseUrl} (SSL ignorado)");
        }

        /// <summary>
        /// Comprueba si la API responde
        /// GET health
        /// </summary>
        public async Task<bool> CheckHealthAsync()
        {
            try
            {
                var response = await _httpClient.GetAsync("health");
                return response.IsSuccessStatusCode;
            }
            catch (Exception ex)
            {
                FileLogger.LogError("Error en Healthcheck", ex);
                return false;
            }
        }

        /// <summary>
        /// Envía heartbeat/registro de la baliza
        /// POST beacons/heartbeat
        /// </summary>
        /// <summary>
        /// Envía heartbeat/registro de la baliza
        /// POST beacons/heartbeat
        /// </summary>
        public async Task SendHeartbeatAsync(BeaconHeartbeatRequest request)
        {
            try
            {
                // 1. Intentar endpoint estándar de heartbeat (lógica de servidor, online status, etc.)
                var response = await _httpClient.PostAsJsonAsync("beacons/heartbeat", request);

                if (response.IsSuccessStatusCode)
                {
                    Log($"✓ Heartbeat enviado ({request.Mode})");
                }
                else
                {
                    Log($"⚠ Error en heartbeat: {response.StatusCode}");
                }

                // 2. FORZAR persistencia de batería y datos vía _upsert
                // Esto asegura que la columna 'battery_level' se rellene aunque el endpoint heartbeat la ignore
                var dbPayload = new 
                { 
                    beacon_uid = request.BeaconUid,
                    battery_level = request.BatteryLevel,
                    // También aseguramos otros datos críticos por si acaso
                    mode = request.Mode,
                    arrow_direction = request.ArrowDirection,
                    last_heartbeat = DateTime.UtcNow.ToString("yyyy-MM-dd HH:mm:ss")
                };
                
                await UpsertAsync("beacons", dbPayload);
            }
            catch (Exception ex)
            {
                FileLogger.LogError("Excepción en heartbeat", ex);
                throw; // Re-lanzar para manejo superior si es necesario
            }
        }

        /// <summary>
        /// Obtiene los comandos pendientes para esta baliza
        /// GET commands/pending/{beaconUid}
        /// </summary>
        public async Task<List<BeaconCommandDto>> GetPendingCommandsAsync(string beaconUid)
        {
            try
            {
                var response = await _httpClient.GetAsync($"commands/pending/{Uri.EscapeDataString(beaconUid)}");

                if (!response.IsSuccessStatusCode)
                {
                    Console.WriteLine($"[API] Error polling commands: {response.StatusCode}");
                    return new List<BeaconCommandDto>();
                }

                var content = await response.Content.ReadAsStringAsync();
                
                if (string.IsNullOrWhiteSpace(content) || content.Trim() == "null")
                {
                    return new List<BeaconCommandDto>();
                }

                Console.WriteLine($"[API] Raw commands: {content}"); // Uncomment for deep debug

                var commands = JsonSerializer.Deserialize<List<BeaconCommandDto>>(content);
                return commands ?? new List<BeaconCommandDto>();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[API] Exception polling commands: {ex.Message}");
                FileLogger.LogError("Error al obtener comandos", ex);
                return new List<BeaconCommandDto>();
            }
        }
        
        /// <summary>
        /// Obtiene la configuración actual de la baliza
        /// GET beacons?beacon_uid={uid}
        /// </summary>
        public async Task<BeaconConfigUpdate?> GetBeaconConfigAsync(string beaconUid)
        {
            try
            {
                // Usamos _get para buscar por beacon_uid
                var payload = new { table = "beacons", where = new { beacon_uid = beaconUid } };
                var response = await _httpClient.PostAsJsonAsync("_get", payload);

                if (!response.IsSuccessStatusCode) return null;

                var content = await response.Content.ReadAsStringAsync();
                var beacons = JsonSerializer.Deserialize<List<JsonElement>>(content);
                
                if (beacons != null && beacons.Count > 0)
                {
                    var b = beacons[0];
                    // Mapear respuesta dinámica a BeaconConfigUpdate
                    return new BeaconConfigUpdate
                    {
                        Mode = GetString(b, "mode"),
                        Arrow = GetString(b, "arrow") ?? GetString(b, "arrow_direction"),
                        Message = GetString(b, "message"),
                        Color = GetString(b, "color"),
                        Brightness = GetInt(b, "brightness"),
                        Zone = GetString(b, "zone"),
                        EvacuationExit = GetString(b, "evacuation_exit")
                    };
                }
                return null;
            }
            catch (Exception ex)
            {
                FileLogger.LogError("Error obteniendo config de baliza", ex);
                return null;
            }
        }
        
        /// <summary>
        /// Obtiene el estado global del circuito
        /// GET circuit_state?id=1 aka _get
        /// </summary>
        public async Task<string?> GetGlobalModeAsync()
        {
            var state = await GetCircuitStateAsync();
            return state?.GlobalMode;
        }

        /// <summary>
        /// Obtiene el estado completo del circuito incluyendo modo y temperatura
        /// GET circuit_state?id=1 aka _get
        /// </summary>
        public async Task<CircuitState?> GetCircuitStateAsync()
        {
            try
            {
                var payload = new { table = "circuit_state", where = new { id = "1" } };
                var response = await _httpClient.PostAsJsonAsync("_get", payload);

                if (!response.IsSuccessStatusCode) return null;

                var content = await response.Content.ReadAsStringAsync();
                var states = JsonSerializer.Deserialize<List<JsonElement>>(content);
                
                if (states != null && states.Count > 0)
                {
                    var row = states[0];
                    return new CircuitState
                    {
                        GlobalMode = GetString(row, "global_mode") ?? "NORMAL",
                        Temperature = GetDouble(row, "temperature"),
                        Message = GetString(row, "message"),
                        EvacuationRoute = GetString(row, "evacuation_route")
                    };
                }
                return null;
            }
            catch (Exception ex)
            {
                FileLogger.LogError("Error obteniendo estado del circuito", ex);
                return null;
            }
        }
    
        private string? GetString(JsonElement element, string property)
        {
            if (element.TryGetProperty(property, out var prop) && prop.ValueKind == JsonValueKind.String)
                return prop.GetString();
            return null;
        }

        private int? GetInt(JsonElement element, string property)
        {
            if (element.TryGetProperty(property, out var prop) && prop.ValueKind == JsonValueKind.Number)
                return prop.GetInt32();
            return null;
        }

        private double? GetDouble(JsonElement element, string property)
        {
            if (element.TryGetProperty(property, out var prop))
            {
                if (prop.ValueKind == JsonValueKind.Number)
                    return prop.GetDouble();
                // Handle string temperature like "11.3°C"
                if (prop.ValueKind == JsonValueKind.String)
                {
                    var str = prop.GetString();
                    if (str != null && double.TryParse(str.Replace("°C", "").Trim(), 
                        System.Globalization.NumberStyles.Any, 
                        System.Globalization.CultureInfo.InvariantCulture, out var result))
                        return result;
                }
            }
            return null;
        }

        /// <summary>
        /// Marca un comando como ejecutado
        /// POST commands/{id}/execute
        /// </summary>
        /// <summary>
        /// Inserta o actualiza un registro en una tabla dinámica
        /// POST /_upsert
        /// </summary>
        public async Task UpsertAsync(string table, object data)
        {
            try
            {
                var payload = new { table, data };
                var response = await _httpClient.PostAsJsonAsync("_upsert", payload);
                
                if (!response.IsSuccessStatusCode)
                {
                    Log($"⚠ Error en _upsert ({table}): {response.StatusCode}");
                }
            }
            catch (Exception ex)
            {
                FileLogger.LogError($"Error en _upsert ({table})", ex);
            }
        }

        /// <summary>
        /// Elimina un registro de una tabla dinámica
        /// POST /_delete
        /// </summary>
        public async Task DeleteAsync(string table, object where)
        {
            try
            {
                var payload = new { table, where };
                var response = await _httpClient.PostAsJsonAsync("_delete", payload);

                if (!response.IsSuccessStatusCode)
                {
                    Log($"⚠ Error en _delete ({table}): {response.StatusCode}");
                }
            }
            catch (Exception ex)
            {
                FileLogger.LogError($"Error en _delete ({table})", ex);
            }
        }

        /// <summary>
        /// Asegura que exista una tabla dinámica
        /// POST /_ensure_table
        /// </summary>
        public async Task EnsureTableAsync(string table)
        {
            try
            {
                var payload = new { table };
                await _httpClient.PostAsJsonAsync("_ensure_table", payload);
            }
            catch (Exception ex)
            {
                FileLogger.LogError($"Error en _ensure_table ({table})", ex);
            }
        }

        /// <summary>
        /// Asegura que exista una columna en una tabla dinámica
        /// POST /_ensure_column
        /// </summary>
        public async Task EnsureColumnAsync(string table, string column, string type)
        {
            try
            {
                var payload = new { table, column, type };
                await _httpClient.PostAsJsonAsync("_ensure_column", payload);
            }
            catch (Exception ex)
            {
                FileLogger.LogError($"Error en _ensure_column ({table}.{column})", ex);
            }
        }

        public async Task ExecuteCommandAsync(string commandId)
        {
            try
            {
                var response = await _httpClient.PostAsync($"commands/{commandId}/execute", null);

                if (response.IsSuccessStatusCode)
                {
                    Log($"✓ Comando {commandId} marcado como EJECUTADO");
                }
                else
                {
                    Log($"⚠ Error al marcar comando {commandId}: {response.StatusCode}");
                }
            }
            catch (Exception ex)
            {
                FileLogger.LogError("Error al marcar comando", ex);
            }
        }

        public async Task<bool> CreateCommandAsync(string beaconUid, string command, string? value = null)
        {
            try
            {
                var payload = new
                {
                    beacon_uid = beaconUid,
                    command = command,
                    value = value ?? "",
                    status = "PENDING"
                };
                
                // Intentamos usar el endpoint estándar REST
                var response = await _httpClient.PostAsJsonAsync("commands", payload);
                
                if (!response.IsSuccessStatusCode)
                {
                    Log($"⚠ Error enviando comando: {response.StatusCode}");
                    
                    // Fallback: Si falla, intentamos por _upsert (por si acaso)
                    if (response.StatusCode == System.Net.HttpStatusCode.NotFound)
                    {
                        Log("⚠ Reintentando con _upsert...");
                        var upsertPayload = new
                        {
                            id = Guid.NewGuid().ToString(), // Generamos ID si usamos upsert
                            beacon_uid = beaconUid,
                            command = command,
                            value = value ?? "",
                            status = "PENDING",
                            created_at = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss")
                        };
                        await UpsertAsync("commands", upsertPayload);
                        return true; // Asumimos éxito si no lanza excepción
                    }
                }
                
                return response.IsSuccessStatusCode;
            }
            catch (Exception ex)
            {
                FileLogger.LogError("Error sending command", ex);
                return false;
            }
        }

        // Removed Dispose to prevent HttpClient from being disposed prematurely by DI container
        // public void Dispose()
        // {
        //     _httpClient?.Dispose();
        // }

        private void Log(string message)
        {
            FileLogger.Log($"[API] {message}");
        }
    }
}

```

---

## `Baliza_Noah/BeaconApp/Services/ApiLogger.cs`

```csharp
using System;
using System.Collections.Concurrent;
using System.Threading.Tasks;
using System.Timers;

namespace BeaconApp.Services
{
    public class ApiLogger
    {
        private readonly ApiClient _apiClient;
        private readonly string _beaconId;
        private readonly ConcurrentQueue<LogEntry> _logQueue;
        private readonly Timer _flushTimer;
        private bool _isInitialized = false;

        public ApiLogger(ApiClient apiClient, string beaconId)
        {
            _apiClient = apiClient;
            _beaconId = beaconId;
            _logQueue = new ConcurrentQueue<LogEntry>();
            
            // Flush logs every 5 seconds
            _flushTimer = new Timer(5000);
            _flushTimer.Elapsed += async (s, e) => await FlushLogsAsync();
            _flushTimer.Start();
        }

        public async Task InitializeAsync()
        {
            if (_isInitialized) return;

            try
            {
                await _apiClient.EnsureTableAsync("beacon_logs");
                await _apiClient.EnsureColumnAsync("beacon_logs", "beacon_uid", "VARCHAR(50)");
                await _apiClient.EnsureColumnAsync("beacon_logs", "level", "VARCHAR(20)");
                await _apiClient.EnsureColumnAsync("beacon_logs", "message", "TEXT");
                await _apiClient.EnsureColumnAsync("beacon_logs", "timestamp", "DATETIME");
                
                _isInitialized = true;
                Log("INFO", "ApiLogger initialized");
            }
            catch (Exception ex)
            {
                FileLogger.LogError("Failed to initialize ApiLogger", ex);
            }
        }

        public void Log(string level, string message)
        {
            // Always log to file first
            FileLogger.Log($"[{level}] {message}");

            // Queue for API
            _logQueue.Enqueue(new LogEntry
            {
                BeaconUid = _beaconId,
                Level = level,
                Message = message,
                Timestamp = DateTime.Now
            });
        }

        private async Task FlushLogsAsync()
        {
            if (!_isInitialized || _logQueue.IsEmpty) return;

            while (_logQueue.TryDequeue(out var entry))
            {
                try
                {
                    // Use _upsert to send log
                    // We generate a unique ID for the log or let the backend handle it if we don't send 'id'
                    // Ideally, we should send an ID if we want to be idempotent, but for logs, fire-and-forget is okay-ish
                    // However, _upsert usually requires a primary key. 
                    // If the backend generates IDs for new rows, we might need to send a unique ID.
                    // Let's assume we generate a GUID for the log ID.
                    
                    var logData = new
                    {
                        id = Guid.NewGuid().ToString(),
                        beacon_uid = entry.BeaconUid,
                        level = entry.Level,
                        message = entry.Message,
                        timestamp = entry.Timestamp.ToString("yyyy-MM-dd HH:mm:ss")
                    };

                    await _apiClient.UpsertAsync("beacon_logs", logData);
                }
                catch (Exception ex)
                {
                    // Don't log to API if API logging fails, just file
                    FileLogger.LogError("Error flushing logs to API", ex);
                }
            }
        }

        private class LogEntry
        {
            public string BeaconUid { get; set; } = string.Empty;
            public string Level { get; set; } = string.Empty;
            public string Message { get; set; } = string.Empty;
            public DateTime Timestamp { get; set; }
        }
    }
}

```

---

## `Baliza_Noah/BeaconApp/Services/BleBeaconService.cs`

```csharp
using System;
using System.Runtime.InteropServices.WindowsRuntime;
using Windows.Devices.Bluetooth;
using Windows.Devices.Bluetooth.Advertisement;
using Windows.Storage.Streams;

namespace BeaconApp.Services
{
    /// <summary>
    /// Servicio BLE Advertising para emitir señales de baliza GeoRacing.
    /// Protocolo: Manufacturer ID 0x1234 con payload de 9 bytes.
    /// </summary>
    public class BleBeaconService
    {
        private readonly int _zoneId;
        private BluetoothLEAdvertisementPublisher? _publisher;
        private ushort _sequenceCounter = 0;
        private byte _currentMode = 0x00;
        private byte _currentTemp = 25;

        // Manufacturer ID GeoRacing
        private const ushort MANUFACTURER_ID = 0x1234;

        /// <summary>
        /// Indica si el advertising BLE está activo
        /// </summary>
        public bool IsRunning => _publisher?.Status == BluetoothLEAdvertisementPublisherStatus.Started;

        public BleBeaconService(int zoneId)
        {
            _zoneId = zoneId;
            Log($"BleBeaconService inicializado para ZoneId: {zoneId}");
        }

        /// <summary>
        /// Inicia el broadcasting BLE
        /// </summary>
        public void Start()
        {
            try
            {
                _publisher = new BluetoothLEAdvertisementPublisher();

                // Crear el advertisement con los datos iniciales
                var manufacturerData = CreateManufacturerData();
                _publisher.Advertisement.ManufacturerData.Add(manufacturerData);

                // Suscribirse a cambios de estado
                _publisher.StatusChanged += OnPublisherStatusChanged;

                // Iniciar broadcasting
                _publisher.Start();
                Log("✓ BLE Advertising iniciado");
            }
            catch (Exception ex)
            {
                Log($"✗ Error al iniciar BLE: {ex.Message}");
                // No crashear la app si BLE no está disponible
            }
        }

        /// <summary>
        /// Detiene el broadcasting BLE
        /// </summary>
        public void Stop()
        {
            try
            {
                if (_publisher != null)
                {
                    _publisher.Stop();
                    _publisher.StatusChanged -= OnPublisherStatusChanged;
                    _publisher = null;
                    Log("✓ BLE Advertising detenido");
                }
            }
            catch (Exception ex)
            {
                Log($"✗ Error al detener BLE: {ex.Message}");
            }
        }

        /// <summary>
        /// Actualiza el payload BLE en tiempo real - solo si hay cambios
        /// </summary>
        /// <param name="mode">Modo: "NORMAL", "CONGESTION", "EMERGENCY", "RED_FLAG", "EVACUATION"</param>
        /// <param name="temperature">Temperatura en grados (0-255)</param>
        public void UpdateStatus(string mode, int temperature = 25)
        {
            try
            {
                // Mapear modo string a byte
                var newMode = MapModeToByte(mode);
                var newTemp = (byte)Math.Clamp(temperature, 0, 255);

                // Solo actualizar si hay cambios reales (evitar Stop/Start innecesarios)
                if (newMode == _currentMode && newTemp == _currentTemp)
                {
                    return; // Sin cambios, no hacer nada
                }

                _currentMode = newMode;
                _currentTemp = newTemp;

                // Incrementar contador de secuencia (indica dato fresco)
                _sequenceCounter++;

                // Recrear el publisher completamente (WinRT no permite reusar después de Stop)
                if (_publisher != null)
                {
                    _publisher.Stop();
                    _publisher.StatusChanged -= OnPublisherStatusChanged;
                }

                _publisher = new BluetoothLEAdvertisementPublisher();
                _publisher.Advertisement.ManufacturerData.Add(CreateManufacturerData());
                _publisher.StatusChanged += OnPublisherStatusChanged;
                _publisher.Start();

                Log($"↻ BLE actualizado: Mode={mode} (0x{_currentMode:X2}), Seq={_sequenceCounter}, Temp={_currentTemp}°C");
            }
            catch (Exception ex)
            {
                Log($"✗ Error actualizando BLE: {ex.Message}");
            }
        }

        /// <summary>
        /// Crea el objeto ManufacturerData con el payload de 9 bytes
        /// </summary>
        private BluetoothLEManufacturerData CreateManufacturerData()
        {
            var manufacturerData = new BluetoothLEManufacturerData
            {
                CompanyId = MANUFACTURER_ID
            };

            // Payload de 9 bytes en Big Endian
            byte[] payload = new byte[9];

            // Byte 0: Versión (siempre 0x01)
            payload[0] = 0x01;

            // Byte 1-2: Zone ID (Big Endian)
            payload[1] = (byte)((_zoneId >> 8) & 0xFF);
            payload[2] = (byte)(_zoneId & 0xFF);

            // Byte 3: Modo (The Scream mapping)
            payload[3] = _currentMode;

            // Byte 4: Flags (siempre 0x00)
            payload[4] = 0x00;

            // Byte 5-6: Secuencia (Big Endian, contador incremental)
            payload[5] = (byte)((_sequenceCounter >> 8) & 0xFF);
            payload[6] = (byte)(_sequenceCounter & 0xFF);

            // Byte 7: TTL (siempre 0x0A = 10 segundos)
            payload[7] = 0x0A;

            // Byte 8: Temperatura
            payload[8] = _currentTemp;

            // Convertir a buffer de Windows Runtime
            var writer = new DataWriter();
            writer.WriteBytes(payload);
            manufacturerData.Data = writer.DetachBuffer();

            return manufacturerData;
        }

        /// <summary>
        /// Mapea strings de modo a bytes del protocolo
        /// </summary>
        private static byte MapModeToByte(string mode)
        {
            return mode?.ToUpperInvariant() switch
            {
                "NORMAL" => 0x00,
                "CONGESTION" => 0x01,
                "SAFETY_CAR" => 0x01,  // Same as congestion (caution flag)
                "EMERGENCY" => 0x02,
                "RED_FLAG" => 0x02,
                "EVACUATION" => 0x03,
                _ => 0x00  // Default: NORMAL
            };
        }

        private void OnPublisherStatusChanged(BluetoothLEAdvertisementPublisher sender, BluetoothLEAdvertisementPublisherStatusChangedEventArgs args)
        {
            var status = args.Status;
            var error = args.Error;

            if (error != BluetoothError.Success)
            {
                Log($"⚠ BLE Error: {error}");
            }

            Log($"BLE Status: {status}");
        }

        private static void Log(string message)
        {
            var timestamp = DateTime.Now.ToString("HH:mm:ss");
            Console.WriteLine($"[{timestamp}] [BLE] {message}");
            FileLogger.Log($"[BLE] {message}");
        }
    }
}

```

---

## `Baliza_Noah/BeaconApp/Services/FileLogger.cs`

```csharp
using System;
using System.IO;

namespace BeaconApp.Services
{
    public static class FileLogger
    {
        private static readonly string LogPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "beacon_log.txt");
        private static readonly object _lock = new object();

        public static void Log(string message)
        {
            try
            {
                lock (_lock)
                {
                    string timestamp = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
                    string logLine = $"{timestamp} {message}{Environment.NewLine}";
                    File.AppendAllText(LogPath, logLine);
                    
                    // También escribir en consola para debug en IDE
                    Console.Write(logLine);
                }
            }
            catch (Exception)
            {
                // Si falla el log, no podemos hacer mucho más, pero evitamos que tumbe la app
            }
        }

        public static void LogError(string context, Exception ex)
        {
            Log($"[ERROR] {context}: {ex.Message}\nStack Trace: {ex.StackTrace}");
        }
    }
}

```

---

## `Baliza_Noah/BeaconApp/ViewModels/MainViewModel.cs`

```csharp
using System;
using System.ComponentModel;
using System.Runtime.CompilerServices;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using System.Windows;
using BeaconApp.Config;
using BeaconApp.Models;
using BeaconApp.Services;

namespace BeaconApp.ViewModels
{
    /// <summary>
    /// ViewModel principal de la aplicación de baliza
    /// </summary>
    public class MainViewModel : INotifyPropertyChanged
    {
        private readonly ApiClient _apiClient;
        private readonly BeaconConfig _config;
        private readonly BleBeaconService _bleService;
        
        private Timer? _pollingTimer;
        private Timer? _heartbeatTimer;
        private CancellationTokenSource? _cts;
        private ApiLogger? _apiLogger;

        // Constantes de temporización
        private const int POLLING_INTERVAL_MS = 300;       // 300ms (lectura rápida DB)
        private const int HEARTBEAT_INTERVAL_MS = 10000;   // 10 segundos (registrarse)
        private DateTime _ignoreDbEvacuationUntil = DateTime.MinValue; // Grace period for DB lag

        // ... (Properties omitted for brevity) ...

        // ============================================
        // CONSTRUCTOR
        // ============================================

        public MainViewModel(BeaconConfig config, ApiClient apiClient)
        {
            _config = config;
            _apiClient = apiClient;
            _cts = new CancellationTokenSource();
            _apiLogger = new ApiLogger(_apiClient, _config.BeaconId);
            _bleService = new BleBeaconService(_config.ZoneId);

            Console.WriteLine($"[VM] ViewModel inicializado para baliza: {_config.BeaconId}");
            Log($"ViewModel inicializado para baliza: {_config.BeaconId}");
        }

        // ============================================
        // MÉTODOS PÚBLICOS
        // ============================================

        /// <summary>
        /// Inicia los servicios de heartbeat y polling
        /// </summary>
        public async Task Start()
        {
            StatusMessage = $"Conectando a API...";

            // 1. Healthcheck
            bool isOnline = await _apiClient.CheckHealthAsync();
            if (!isOnline)
            {
                StatusMessage = "⚠ SIN CONEXIÓN A API";
                Log("⚠ API no responde en el inicio");
            }
            else
            {
                StatusMessage = "✓ Conectado";
                Log("✓ API Online");

                // Sincronizar estado inicial
                await SyncConfigAsync();
            }

            // Inicializar Logger API
            if (_apiLogger != null)
            {
                await _apiLogger.InitializeAsync();
            }

            // 2. Iniciar Timers
            Log("🚀 Iniciando servicios de fondo (300ms)...");

            // Timer 1: Polling (leer comandos + sync config)
            _pollingTimer = new Timer(
                async _ => 
                {
                    await CheckGlobalStateAsync(); // Prioridad: Estado Global
                    await SyncConfigAsync();    // Leer estado DB individual
                    await PollCommandsAsync();  // Leer comandos
                },
                null,
                TimeSpan.FromMilliseconds(1000),
                TimeSpan.FromMilliseconds(POLLING_INTERVAL_MS)
            );

            // Timer 2: Heartbeat (registrarse)
            _heartbeatTimer = new Timer(
                async _ => await SendHeartbeatAsync(),
                null,
                TimeSpan.Zero,  // Enviar inmediatamente
                TimeSpan.FromMilliseconds(HEARTBEAT_INTERVAL_MS)
            );

            // Iniciar BLE Advertising
            _bleService.Start();
        }

        /// <summary>
        /// Detiene los servicios
        /// </summary>
        public void Stop()
        {
            _cts?.Cancel();
            _pollingTimer?.Dispose();
            _heartbeatTimer?.Dispose();
            _bleService.Stop();
            
            Log("✓ Servicios detenidos");
        }

        private string _backgroundColor = "#2E7D32";
        public string BackgroundColor
        {
            get => _backgroundColor;
            set
            {
                if (_backgroundColor != value)
                {
                    _backgroundColor = value;
                    OnPropertyChanged();
                }
            }
        }

        private string _currentLanguage = "ES";
        public string CurrentLanguage
        {
            get => _currentLanguage;
            set
            {
                if (_currentLanguage != value)
                {
                    _currentLanguage = value;
                    OnPropertyChanged();
                }
            }
        }

        private string _currentEvacuationExit = string.Empty;
        public string CurrentEvacuationExit
        {
            get => _currentEvacuationExit;
            set
            {
                if (_currentEvacuationExit != value)
                {
                    _currentEvacuationExit = value;
                    OnPropertyChanged();
                }
            }
        }

        private bool _isConfigured = false;
        public bool IsConfigured
        {
            get => _isConfigured;
            set
            {
                if (_isConfigured != value)
                {
                    _isConfigured = value;
                    OnPropertyChanged();
                }
            }
        }

        // ============================================
        // SYNC & HEARTBEAT
        // ============================================

        private async Task SyncConfigAsync()
        {
            try
            {
                var remoteConfig = await _apiClient.GetBeaconConfigAsync(_config.BeaconId);
                
                if (remoteConfig != null)
                {
                    Application.Current.Dispatcher.Invoke(() =>
                    {
                        bool changed = false;
                        if (!string.IsNullOrEmpty(remoteConfig.Mode) && remoteConfig.Mode != CurrentMode)
                        {
                            // LOGIC: Conflict Resolution

                            // 1. Block flickering: If Global is EVACUATION, ignore individual NORMAL
                            if (_lastGlobalMode == "EVACUATION" && remoteConfig.Mode != "EVACUATION")
                            {
                                // Ignore downgrade
                            }
                            // 2. Block Stale Revert: If we just exited Global Evacuation, ignore individual EVACUATION for a few seconds
                            else if (remoteConfig.Mode == "EVACUATION" && DateTime.Now < _ignoreDbEvacuationUntil)
                            {
                                // Ignore stale DB config
                                // Log("Ignorando configuración EVACUATION antigua (DB lag)");
                            }
                            else
                            {
                                CurrentMode = remoteConfig.Mode;
                                changed = true;
                            }
                        }
                        if (!string.IsNullOrEmpty(remoteConfig.Arrow) && remoteConfig.Arrow != CurrentArrow)
                        {
                            CurrentArrow = remoteConfig.Arrow;
                            changed = true;
                        }
                        if (!string.IsNullOrEmpty(remoteConfig.Message) && remoteConfig.Message != DisplayText)
                        {
                            DisplayText = remoteConfig.Message;
                            changed = true;
                        }
                        if (!string.IsNullOrEmpty(remoteConfig.Color) && remoteConfig.Color != BackgroundColor)
                        {
                            BackgroundColor = remoteConfig.Color;
                            changed = true;
                        }
                        if (remoteConfig.Brightness.HasValue && remoteConfig.Brightness.Value != CurrentBrightness)
                        {
                            CurrentBrightness = remoteConfig.Brightness.Value;
                            changed = true;
                        }
                        if (!string.IsNullOrEmpty(remoteConfig.Zone) && remoteConfig.Zone != CurrentZone)
                        {
                            CurrentZone = remoteConfig.Zone;
                            changed = true;
                        }
                        if (!string.IsNullOrEmpty(remoteConfig.EvacuationExit) && remoteConfig.EvacuationExit != CurrentEvacuationExit)
                        {
                            CurrentEvacuationExit = remoteConfig.EvacuationExit;
                            changed = true;
                        }
                        
                        // Solo loguear si hubo cambio para no saturar
                        if (changed) Log($"↻ Sincronizado: {CurrentMode}");
                    });
                }
            }
            catch (Exception ex)
            {
                // No loguear error en cada tick de 300ms para no saturar, solo consola debug si es necesario
                System.Diagnostics.Debug.WriteLine($"Error sync: {ex.Message}");
            }
        }

        private async Task SendHeartbeatAsync()
        {
            if (_cts?.Token.IsCancellationRequested ?? true) return;

            try
            {
                // Ya no necesitamos sincronizar aquí porque lo hace el polling cada 300ms
                // Simplemente enviamos el estado actual

                var heartbeat = new BeaconHeartbeatRequest
                {
                    BeaconUid = _config.BeaconId,
                    Name = _config.Name,
                    Description = _config.Description,
                    ZoneId = _config.ZoneId,
                    Latitude = _config.Latitude,
                    Longitude = _config.Longitude,
                    HasScreen = 1,
                    Mode = CurrentMode,
                    ArrowDirection = CurrentArrow,
                    Message = DisplayText,
                    Color = BackgroundColor,
                    Brightness = CurrentBrightness,
                    BatteryLevel = (int)(System.Windows.Forms.SystemInformation.PowerStatus.BatteryLifePercent * 100)
                };

                await _apiClient.SendHeartbeatAsync(heartbeat);
            }
            catch (Exception ex)
            {
                Log($"✗ Error al enviar heartbeat: {ex.Message}");
            }
        }

        // ============================================
        // GLOBAL STATE CHECK
        // ============================================

        private string _lastGlobalMode = "";

        private async Task CheckGlobalStateAsync()
        {
            try
            {
                // Get full circuit state including mode and temperature
                var circuitState = await _apiClient.GetCircuitStateAsync();
                
                if (circuitState != null && !string.IsNullOrEmpty(circuitState.GlobalMode))
                {
                    var globalMode = circuitState.GlobalMode;
                    var circuitTemp = (int)(circuitState.Temperature ?? 25);

                    // Update BLE with current circuit state (mode + temperature)
                    _bleService.UpdateStatus(globalMode, circuitTemp);

                    // Si el modo global es EVACUACIÓN, forzamos localmente
                    if (globalMode == "EVACUATION")
                    {
                        if (CurrentMode != "EVACUATION")
                        {
                            Application.Current.Dispatcher.Invoke(() => 
                            {
                                CurrentMode = "EVACUATION";
                                // Forzar flecha arriba/salida por defecto si no tenemos una específica
                                if (string.IsNullOrEmpty(CurrentArrow) || CurrentArrow == "NONE")
                                    CurrentArrow = "UP"; 
                                
                                DisplayText = "EVACUACIÓN";
                            });
                            Log("🚨 MODO GLOBAL EVACUACIÓN ACTIVADO");
                        }
                    }
                    else if (globalMode != "EVACUATION" && _lastGlobalMode == "EVACUATION")
                    {
                        // SALIDA DE EVACUACIÓN DETECTADA
                        // 1. Forzamos modo local al nuevo modo global inmediatamente
                        Application.Current.Dispatcher.Invoke(() => 
                        {
                            CurrentMode = globalMode; // "NORMAL", "SAFETY_CAR", etc.
                            DisplayText = "SISTEMA RESTAURADO";
                            
                            // Resetear flechas si estaban forzadas
                            if (CurrentArrow == "UP") CurrentArrow = "NONE";
                        });

                        // 2. Establecer periodo de gracia (5s) para ignorar config antigua de la BD
                        // Esto da tiempo al backend para actualizar la tabla 'beacons' sin que la App vuelva a ponerse roja
                        _ignoreDbEvacuationUntil = DateTime.Now.AddSeconds(5);

                        Log($"✓ FIN DE EVACUACIÓN GLOBAL - Cambiando a {globalMode}");
                    }
                    _lastGlobalMode = globalMode;
                }
            }
            catch (Exception)
            {
                // Silent
            }
        }

        // ============================================
        // POLLING DE COMANDOS
        // ============================================

        private async Task PollCommandsAsync()
        {
            if (_cts?.Token.IsCancellationRequested ?? true) return;

            try
            {
                var commands = await _apiClient.GetPendingCommandsAsync(_config.BeaconId);

                foreach (var cmd in commands)
                {
                    // Check expiration (60 minutes to handle timezone skews)
                    // El servidor envía UTC (toISOString), así que comparamos con UtcNow
                    var age = DateTime.UtcNow - cmd.CreatedAt;
                    
                    // Debug de tiempos para verificar
                    // Log($"[DEBUG] Cmd: {cmd.CreatedAt}, NowUTC: {DateTime.UtcNow}, Age: {age.TotalMinutes:F1} min");

                    if (age > TimeSpan.FromMinutes(60))
                    {
                        Log($"⚠ Comando expirado (ignorando): {cmd.Command} (ID: {cmd.Id}). Age: {age.TotalMinutes:F1} min");
                        // Delete from DB
                        await _apiClient.DeleteAsync("commands", new { id = cmd.Id });
                        continue;
                    }

                    Log($"[CMD] Recibido: {cmd.Command} (ID: {cmd.Id})");
                    
                    bool success = await ProcessCommandAsync(cmd);
                    
                    if (success)
                    {
                        // Delete from DB instead of marking executed
                        await _apiClient.DeleteAsync("commands", new { id = cmd.Id });
                    }
                }
            }
            catch (Exception)
            {
                // Silencioso en bucle rápido
            }
        }

        private string _currentMode = "NORMAL";
        public string CurrentMode
        {
            get => _currentMode;
            set
            {
                // Normalize to uppercase for XAML triggers
                var normalized = value?.ToUpper() ?? "NORMAL";
                if (_currentMode != normalized)
                {
                    _currentMode = normalized;
                    OnPropertyChanged();
                    UpdateDisplayForMode();
                    
                    // Actualizar BLE Advertising con el nuevo modo
                    _bleService.UpdateStatus(normalized);
                }
            }
        }

        private string _currentZone = "Sistema iniciado";
        public string CurrentZone
        {
            get => _currentZone;
            set
            {
                if (_currentZone != value)
                {
                    _currentZone = value;
                    OnPropertyChanged();
                }
            }
        }

        private string _currentArrow = "NONE";
        public string CurrentArrow
        {
            get => _currentArrow;
            set
            {
                // Normalize to uppercase for XAML triggers
                var normalized = value?.ToUpper() ?? "NONE";
                if (_currentArrow != normalized)
                {
                    _currentArrow = normalized;
                    OnPropertyChanged();
                }
            }
        }

        private int _currentBrightness = 100;
        public int CurrentBrightness
        {
            get => _currentBrightness;
            set
            {
                if (_currentBrightness != value)
                {
                    _currentBrightness = value;
                    OnPropertyChanged();
                    SetWindowsBrightness(value);
                }
            }
        }

        private void SetWindowsBrightness(int brightness)
        {
            try
            {
                // Asegurar rango 0-100
                brightness = Math.Max(0, Math.Min(100, brightness));

                var psi = new System.Diagnostics.ProcessStartInfo
                {
                    FileName = "powershell",
                    Arguments = $"-Command \"(Get-WmiObject -Namespace root/wmi -Class WmiMonitorBrightnessMethods).WmiSetBrightness(1, {brightness})\"",
                    UseShellExecute = false,
                    CreateNoWindow = true
                };
                System.Diagnostics.Process.Start(psi);
            }
            catch (Exception ex)
            {
                Log($"⚠ Error ajustando brillo Windows: {ex.Message}");
            }
        }

        public double BrightnessOpacity => 1.0 - (_currentBrightness / 100.0);

        private string _statusMessage = "Iniciando...";
        public string StatusMessage
        {
            get => _statusMessage;
            set
            {
                if (_statusMessage != value)
                {
                    _statusMessage = value;
                    OnPropertyChanged();
                }
            }
        }

        private string _displayText = "SISTEMA LISTO";
        public string DisplayText
        {
            get => _displayText;
            set
            {
                if (_displayText != value)
                {
                    _displayText = value;
                    OnPropertyChanged();
                }
            }
        }

        private Task<bool> ProcessCommandAsync(BeaconCommandDto cmd)
        {
            try
            {
                switch (cmd.Command.ToUpper())
                {
                    case "UPDATE_CONFIG":
                        return Task.FromResult(ProcessUpdateConfig(cmd.Value));

                    case "RESTART":
                        return Task.FromResult(ProcessRestart());

                    case "SHUTDOWN":
                        return Task.FromResult(ProcessShutdown());

                    case "CLOSE":
                    case "CLOSE_APP":
                        return Task.FromResult(ProcessCloseApp());

                    default:
                        Log($"⚠ Comando desconocido: {cmd.Command}");
                        return Task.FromResult(true); // Marcar como ejecutado para no bloquear
                }
            }
            catch (Exception ex)
            {
                Log($"✗ Error procesando comando {cmd.Command}: {ex.Message}");
                return Task.FromResult(false);
            }
        }

        private bool ProcessUpdateConfig(string jsonValue)
        {
            try
            {
                var config = JsonSerializer.Deserialize<BeaconConfigUpdate>(jsonValue);
                if (config == null) return false;

                Application.Current.Dispatcher.Invoke(() =>
                {
                    if (!string.IsNullOrEmpty(config.Mode))
                        CurrentMode = config.Mode;

                    if (!string.IsNullOrEmpty(config.Arrow))
                        CurrentArrow = config.Arrow;

                    if (!string.IsNullOrEmpty(config.Message))
                        DisplayText = config.Message;

                    if (!string.IsNullOrEmpty(config.Color))
                        BackgroundColor = config.Color;

                    if (config.Brightness.HasValue)
                        CurrentBrightness = config.Brightness.Value;

                    if (config.EvacuationExit != null)
                        CurrentEvacuationExit = config.EvacuationExit;

                    if (!string.IsNullOrEmpty(config.Zone))
                        CurrentZone = config.Zone;
                });

                Log("✓ Configuración actualizada");
                return true;
            }
            catch (Exception ex)
            {
                Log($"✗ Error deserializando config: {ex.Message}");
                return false;
            }
        }

        private bool ProcessRestart()
        {
            Log("🔄 Ejecutando REINICIO DE WINDOWS...");
            
            try 
            {
                // Delay 3s to allow command deletion from DB
                var psi = new System.Diagnostics.ProcessStartInfo("shutdown.exe", "/r /f /t 3")
                {
                    CreateNoWindow = true,
                    UseShellExecute = false
                };
                System.Diagnostics.Process.Start(psi);
                return true;
            }
            catch (Exception ex)
            {
                Log($"✗ Error al reiniciar Windows: {ex.Message}");
                return false;
            }
        }

        private bool ProcessShutdown()
        {
            Log("🔌 Ejecutando APAGADO DE WINDOWS...");
            
            try 
            {
                // Delay 3s to allow command deletion
                var psi = new System.Diagnostics.ProcessStartInfo("shutdown.exe", "/s /f /t 3")
                {
                    CreateNoWindow = true,
                    UseShellExecute = false,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true
                };
                
                Log($"[DEBUG] Ejecutando: {psi.FileName} {psi.Arguments}");
                
                var process = System.Diagnostics.Process.Start(psi);
                if (process != null)
                {
                    process.WaitForExit(1000); // Esperar un poco para ver si falla inmediato
                    if (process.HasExited && process.ExitCode != 0)
                    {
                         var error = process.StandardError.ReadToEnd();
                         Log($"✗ shutdown.exe falló con código {process.ExitCode}: {error}");
                         return false;
                    }
                }
                
                return true;
            }
            catch (Exception ex)
            {
                Log($"✗ Error CRÍTICO al apagar Windows: {ex.Message}");
                return false;
            }
        }

        private bool ProcessCloseApp()
        {
            Log("❌ Cerrando aplicación en 2 segundos...");
            
            // Run in background to allow returning 'true' immediately so checking loop can delete the command
            Task.Run(async () => 
            {
                await Task.Delay(2000);
                Application.Current.Dispatcher.Invoke(() =>
                {
                    Application.Current.Shutdown();
                });
            });
            
            return true;
        }

        // ============================================
        // ACTUALIZACIÓN DE DISPLAY
        // ============================================

        private void UpdateDisplayForMode()
        {
            // Solo actualiza si NO se ha establecido un mensaje/color manual recientemente
            // Pero en este diseño, UPDATE_CONFIG sobrescribe todo, así que podemos dejar defaults
            // como fallback si el mensaje viene vacío.
            
            // Lógica simplificada: Si el modo cambia, ponemos defaults, 
            // pero si viene un mensaje específico en el mismo comando, ese prevalecerá 
            // porque se asigna después en ProcessUpdateConfig.
            
            UpdateDefaultTextForMode();
            UpdateDefaultColorForMode();
        }

        private void UpdateDefaultTextForMode()
        {
            // Solo cambiar si no hay un mensaje personalizado activo? 
            // Para simplificar, al cambiar de modo reseteamos a default.
            DisplayText = CurrentMode?.ToUpper() switch
            {
                "UNCONFIGURED" => "SIN CONFIGURAR",
                "NORMAL" => "MODO NORMAL",
                "CONGESTION" => "⚠️ CONGESTIÓN",
                "EMERGENCY" => "🚨 EMERGENCIA",
                "EVACUATION" => "🚨 EVACUACIÓN",
                "MAINTENANCE" => "🔧 MANTENIMIENTO",
                _ => "SISTEMA LISTO"
            };
        }

        private void UpdateDefaultColorForMode()
        {
            BackgroundColor = CurrentMode?.ToUpper() switch
            {
                "UNCONFIGURED" => "#1565C0",
                "NORMAL" => "#2E7D32",
                "CONGESTION" => "#F57C00",
                "EMERGENCY" => "#C62828",
                "EVACUATION" => "#D32F2F",
                "MAINTENANCE" => "#7B1FA2",
                _ => "#424242"
            };
        }

        // ============================================
        // INotifyPropertyChanged
        // ============================================

        public event PropertyChangedEventHandler? PropertyChanged;

        protected virtual void OnPropertyChanged([CallerMemberName] string? propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }

        private void Log(string message)
        {
            // Escribir siempre en consola para debug inmediato
            Console.WriteLine($"[LOG] {message}");

            // Log local y API
            _apiLogger?.Log("INFO", message);
            
            // Fallback si el logger no está listo (aunque ApiLogger ya llama a FileLogger)
            if (_apiLogger == null)
            {
                FileLogger.Log($"[VM] {message}");
            }
        }
    }
}

```

