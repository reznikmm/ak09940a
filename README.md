# AK09940A

[![Build status](https://github.com/reznikmm/ak09940a/actions/workflows/alire.yml/badge.svg)](https://github.com/reznikmm/ak09940a/actions/workflows/alire.yml)
[![Alire](https://img.shields.io/endpoint?url=https://alire.ada.dev/badges/ak09940a.json)](https://alire.ada.dev/crates/ak09940a.html)
[![REUSE status](https://api.reuse.software/badge/github.com/reznikmm/ak09940a)](https://api.reuse.software/info/github.com/reznikmm/ak09940a)

> Driver for AK09940A magnetic sensor.

- [Official website](https://www.akm.com/eu/en/products/tri-axis-magnetic-sensor/lineup-tri-axis-magnetic-sensor/ak09940a/)

Key Features

- Low noise of 120nTrms and ultra-low current consumption of 16μA@100Hz make
  it suitable for devices that use small-capacity batteries.

- High-speed sampling at up to 2.5kHz allows for high-speed tracking, making
  it possible to use in motion tracking.

- The external trigger input function and the serial interface specifications
  are convenient for synchronous measurement of multiple sensors.

The AK09940A driver enables the following functionalities:

- Detect the presence of the sensor.
- Perform soft reset
- Configure the sensor (operation mode, frequency, drive)
- Conduct measurements as raw 18-bit values and scaled values.

## Install

Add `ak09940a` as a dependency to your crate with Alire:

    alr with ak09940a

## Usage

The sensor supports SPI (mode 3, no auto-increment address on write)
with a frequency of up to 3.3 MHz and I2C at frequencies up to 400 kHz.

The driver implements two usage models: the generic package, which is more
convenient when dealing with a single sensor, and the tagged type, which
allows easy creation of objects for any number of sensors and uniform handling.

Generic instantiation looks like this:

```ada
declare
   package AK09940A_I2C is new AK09940A.I2C
     (I2C_Port    => STM32.Device.I2C_1'Access,
      I2C_Address => 16#0C#);

begin
   if AK09940A_I2C.Check_Chip_Id then
      ...
```

While declaring object of the tagged type looks like this:

```ada
declare
   Sensor : AK09940A.I2C_Sensors.AK09940A_Sensor
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
  - `External_Trigger`
  - `Self_Test`
- `Drive`: Select low power drive or (ultra-)low noise drive
- `Use_FIFO`: Enable or disable FIFO
- `Watermark`: FIFO watermark
- `Trigger_Pin`: Turn DRDY pin to TRG pin.
- `Frequency`: Set sampling frequency (for Continuous mode only)


An example:
```ada
Sensor.Configure
  ((Mode      => AK09940A.Continuous_Measurement,
    Drive     => AK09940A.Low_Noise_Drive_1,
    Frequency => 50,  --  50 Hz
    others    => <>),
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

### Low-Level Interface: `AK09940A.Raw`

The `AK09940A.Raw` package provides a low-level interface for interacting with
the AK09940A sensor. This package is designed to handle encoding and decoding
of sensor register values, while allowing users to implement the actual
read/write operations in a way that suits their hardware setup. The
communication with the sensor is done by reading or writing one or more bytes
to predefined registers. This package does not depend on HAL and can be used
with DMA or any other method of interacting with the sensor.

#### Purpose of AK09940A.Raw

The package defines array subtypes where the index represents the register
number, and the value corresponds to the register's data. Functions in this
package help prepare and interpret the register values. For example, functions
prefixed with `Set_` create the values for writing to registers, while those
prefixed with `Get_` decode the values read from registers. Additionally,
functions starting with `Is_` handle boolean logic values, such as checking
if the sensor is measuring or updating.

Users are responsible for implementing the reading and writing of these
register values to the sensor.

#### SPI and I2C Functions

The package also provides helper functions for handling SPI and I2C
communication with the sensor. For write operations, the register
address is sent first, followed by one or more data bytes, as the
sensor allows multi-byte writes. For read operations, the register
address is sent first, and then consecutive data can be read without
needing to specify the address for each subsequent byte.

- Two functions convert register address to byte:

  ```ada
  function SPI_Write (X : Register_Address) return Byte;
  function SPI_Read (X : Register_Address) return Byte;
  ```

- Other functions prefix a byte array with the register address:

  ```ada
    function SPI_Write (X : Byte_Array) return Byte_Array;
    function SPI_Read (X : Byte_Array) return Byte_Array
    function I2C_Write (X : Byte_Array) return Byte_Array;
    function I2C_Read (X : Byte_Array) return Byte_Array;
  ```

These functions help abstract the specifics of SPI and I2C communication,
making it easier to focus on the sensor’s register interactions without
worrying about protocol details. For example, you configure the sensor
with low power preset:

```ada
declare
   Data : Byte_Array := AK09940A.Raw.SPI_Write
    (AK09940A.Raw.Set_Configuration
      ((AK09940A.Power_Down, others => <>)));
begin
   --  Now write Data to the sensor by SPI
```

The reading looks like this:

```ada
declare
   Data   : Byte_Array := AK09940A.Raw.SPI_Read
    ((AK09940A.Raw.Measurement_Data => 0));
   Result : AK09940A.Magnetic_Field_Vector;
begin
   --  Start SPI exchange (read/write) then decode Data:
   Result := AK09940A.Raw.Get_Measurement (Data, Trim);
```

## Examples

Examples use `Ada_Drivers_Library`. It's installed by Alire (alr >= 2.1.0 required).
Run Alire to build:

    alr -C examples build

### GNAT Studio

Launch GNAT Studio with Alire:

    alr -C examples exec gnatstudio -- -P ak09940a_put/ak09940a_put.gpr

### VS Code

Make sure `alr` in the `PATH`.
Open the `examples` folder in VS Code. Use pre-configured tasks to build
projects and flash (openocd or st-util). Install Cortex Debug extension
to launch pre-configured debugger targets.

- [Simple example for STM32 F4VE board](examples/ak09940a_put) - complete
  example for the generic instantiation.
- [SPI and IRQ example for STM32 F4VE board](examples/ak09940a_spi) - complete
  example for the SPI generic instantiation with IRQ handling.
- [Advanced example for STM32 F4VE board and LCD & touch panel](examples/ak09940a_lcd) -
  complete example of the tagged type usage.
