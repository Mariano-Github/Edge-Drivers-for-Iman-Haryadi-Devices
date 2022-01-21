## (NEW RELEASE) New Edge Beta Driver: Zigbee Environment Sensor:

My thanks to who have assisted in the sensor tests and suggestions!!!.

This new Edge Driver is a conversion of the DTH: Environment-sensor-ex.groovy o f @iharyadi

https://github.com/iharyadi/zigbee_repeater/blob/master/devicetypes/iharyadi/environment-sensor-ex.src/environment-sensor-ex.groovy

This is the link to the Thread of the previous DTH

https://community.smartthings.com/t/expandable-zigbee-repeater-solution-with-temperature-humidity-pressure-and-light-sensors/123815/465

Link to SmartThings community Thread:

https://community.smartthings.com/t/new-release-new-edge-beta-driver-zigbee-environment-sensor/237401?u=mariano_colmenarejo

You can control the BME280 Environment Sensor and other similar models developed by @iharyadi

This controller shows in the App a single device with the capabilities and functions. Run Local in Hub:

Temperature

Relative humidity

Atmospheric Pressure (kPa and mBar)

Illuminance

Binary Input: Stock Motion Sensor Capability

Analog Input: Stock Water Sensor Capability

Soil Water Probe Voltage

Moisture Percentage of the soil probe

Analog Output: Controllable output of 3 vdc or 0vdc

This is the Link to Edge driver Channel

https://account.smartthings.com/?redirect=https%3A%2F%2Fapi.smartthings.com%2Finvite%2FakMX10g0GA2b%3F

  With Edge Driver "Zigbee Environment Sensor"
 ![Screenshot_20220111-133638](https://user-images.githubusercontent.com/74271621/150534286-f6d3c3e9-7a39-442b-af0c-48db3d4fdf19.png)


- Can be used as Environment Sensor withot External inputs and output:

    -  As Temperature, Humidity, Atmospheric pressure and Illuminance, with Edge Driver "Zigbee Temp Humidity Sensor Mc"
    
    ![Screenshot_20220107-183133](https://user-images.githubusercontent.com/74271621/150534415-59f7fd91-07e8-4e4f-8a62-9d2edfa8605a.png)


    -  As Complete Thermostat working locally, with Edge Driver "Zigbee Temp Sensor with Thermostat Mc"
   ![Screenshot_20220121-131710-2](https://user-images.githubusercontent.com/74271621/150534721-448941e0-bd94-4900-b1df-bb5189fb27a4.png)

   
   ![Screenshot_20220121-131731](https://user-images.githubusercontent.com/74271621/150534463-5bc93948-a108-4b55-991e-9f090b6ed77c.png)


## Supported deviced (jan 2022)

zigbeeManufacturer:

  - id: "KMPCIL/sensor"

    deviceLabel: Environment Sensor

    manufacturer: KMPCIL

    model: RES001

    deviceProfileName: temp-humid-press-illumin

  - id: "KMPCIL/BME280"

    deviceLabel: Environment Sensor BME280

    manufacturer: KMPCIL

    model: RES001BME280

    deviceProfileName: temp-humid-press-illumin

  - id: "KMPCIL/RES005"

    deviceLabel: Environment Sensor RES005

    manufacturer: KMPCIL

    model: RES005
    
    deviceProfileName: temp-humid-press-illumin
