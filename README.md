# AK09940

[![Build status](https://github.com/reznikmm/ak09940/actions/workflows/alire.yml/badge.svg)](https://github.com/reznikmm/ak09940/actions/workflows/alire.yml)
[![Alire](https://img.shields.io/endpoint?url=https://alire.ada.dev/badges/ak09940.json)](https://alire.ada.dev/crates/ak09940.html)
[![REUSE status](https://api.reuse.software/badge/github.com/reznikmm/ak09940)](https://api.reuse.software/info/github.com/reznikmm/ak09940)

> Driver for AK09940 magnetic sensor.

- [Official website](https://www.akm.com/eu/en/products/tri-axis-magnetic-sensor/lineup-tri-axis-magnetic-sensor/ak09940a/)

Key Features

- Low noise of 120nTrms and ultra-low current consumption of 16μA@100Hz make
  it suitable for devices that use small-capacity batteries.

- High-speed sampling at up to 2.5kHz allows for high-speed tracking, making
  it possible to use in motion tracking.

- The external trigger input function and the serial interface specifications
  are convenient for synchronous measurement of multiple sensors.

The AK09940 driver enables the following functionalities:

- Detect the presence of the sensor.
- Perform soft reset
- Configure the sensor (operation mode, frequency, drive)
- Conduct measurements as raw 18-bit values and scaled values.

## Install

Add `ak09940` as a dependency to your crate with Alire:

    alr with ak09940

## Usage

The driver implements two usage models: the generic package, which is more
convenient when dealing with a single sensor, and the tagged type, which
allows easy creation of objects for any number of sensors and uniform handling.

Generic instantiation looks like this:

```ada
declare
   package AK09940_I2C is new HCM5883.I2C
     (I2C_Port    => STM32.Device.I2C_1'Access,
      I2C_Address => 16#0C#);

begin
   if AK09940_I2C.Check_Chip_Id then
      ...
```

While declaring object of the tagged type looks like this:

```ada
declare
   Sensor : AK09940.I2C_Sensors.AK09940_Sensor
     (I2C_Port    => STM32.Device.I2C_1'Access,
      I2C_Address => 16#0C#);
begin
   if Sensor.Check_Chip_Id then
      ...
```

### Sensor Configuration

To configure the sensor, use the Configure procedure by passing the settings
(`Sensor_Configuration` type).

Settings include:

- `Mode`: Switch between modes
  - `Power_Down`
  - `Single_Measurement`
  - `Continuous_Measurement`
  - `Self_Test`

- `Drive`: Select low power drive or low noise drive

- `Use_FIFO`: Enable or disable FIFO

- `Frequency`: Set sampling frequency (for Continuous mode only)


An example:
```ada
Sensor.Configure
  ((Mode      => AK09940.Continuous_Measurement,
    Drive     => AK09940.Low_Noise_Drive_1,
    Frequency => 50,  --  50 Hz
    Use_FIFO  => False),
   Ok);
```

### Read Measurement

The best way to determine data readiness is through interrupts using
a separate pin. Otherwise you can ascertain that the data is ready by
waiting while `Is_Data_Ready` returns `True`.

Read raw data (as provided by the sensor) with the `Read_Raw_Measurement`
procedure.

Calling `Read_Measurement` returns scaled measurements in Gauss based on
the current `Full_Range` setting.

## Examples

You need `Ada_Drivers_Library` in `adl` directory. Clone it then run Alire
to build:

    git clone https://github.com/AdaCore/Ada_Drivers_Library.git adl
    cd examples
    alr build

### GNAT Studio

Launch GNAT Studio with Alire:

    cd examples; alr exec gnatstudio -- -P ak09940_put/ak09940_put.gpr

### VS Code

Make sure `alr` in the `PATH`.
Open the `examples` folder in VS Code. Use pre-configured tasks to build
projects and flash (openocd or st-util). Install Cortex Debug extension
to launch pre-configured debugger targets.

- [Simple example for STM32 F4VE board](examples/ak09940_put) - complete
  example for the generic instantiation.
- [Advanced example for STM32 F4VE board and LCD & touch panel](examples/ak09940_lcd) -
  complete example of the tagged type usage.
