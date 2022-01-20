-- Copyright 2021 SmartThings
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

------ Author Mariano Colmenarejo (Jan 2022) --------
------ Version 1 -----------------

-- default libraries
local capabilities = require "st.capabilities"
local ZigbeeDriver = require "st.zigbee"
local defaults = require "st.zigbee.defaults"
local constants = require "st.zigbee.constants"

local write_attribute = require "st.zigbee.zcl.global_commands.write_attribute"
local zcl_messages = require "st.zigbee.zcl"
local messages = require "st.zigbee.messages"
local zb_const = require "st.zigbee.constants"

local last_vdd = 0

--- default Temperature Mesurement config
local zcl_clusters = require "st.zigbee.zcl.clusters"
local tempMeasurement = zcl_clusters.TemperatureMeasurement
local device_management = require "st.zigbee.device_management"
local tempMeasurement_defaults = require "st.zigbee.defaults.temperatureMeasurement_defaults"

-- defaul Humidity tempMeasurement
local HumidityCluster = require ("st.zigbee.zcl.clusters").RelativeHumidity
local utils = require "st.utils"

-- defualt illuminance
local clusters = require "st.zigbee.zcl.clusters"
local IlluminanceMeasurement = clusters.IlluminanceMeasurement

---- Analoginput and binaryinput clusters and attributes
local BasicInput = zcl_clusters.BasicInput
local data_types = require "st.zigbee.data_types"
local cluster_base_index = require "st.zigbee.cluster_base"

local ANALOG_INPUT_CLUSTER = 0x000C
local ANALOG_INPUT_ENABLE_ATTR_ID = 0x0051
local ANALOG_INPUT_ADC_ATTR_ID = 0x0103
local ANALOG_INPUT_VDD_ATTR_ID = 0x0104
local BINARY_INPUT_CLUSTER = 0x000F
local BINARY_INPUT_ATTR_ID = 0x0055
local BINARY_INPUT_ENABLE_ATTR_ID = 0x0051
local BINARY_OUTPUT_CLUSTER = 0x0010
local BINARY_OUTPUT_ATTR_ID = 0x0055
local BINARY_OUTPUT_ENABLE_ATTR_ID = 0x0051


-- Custom Capability declaration
local atmos_Pressure = capabilities ["legendabsolute60149.atmosPressure"]
local analog_Input_Enable = capabilities ["legendabsolute60149.analogInputEnable"]
local binary_Input_Enable = capabilities ["legendabsolute60149.binaryInputEnable"]
local binary_Output_Enable = capabilities ["legendabsolute60149.binaryOutputEnable"]
local moisture_Water_Sensor = capabilities ["legendabsolute60149.moistureWaterSensor"]

------- Write attribute ----
local function write_attribute_function(device, cluster_id, attr_id, data_value)
  local write_body = write_attribute.WriteAttribute({
   write_attribute.WriteAttribute.AttributeRecord(attr_id, data_types.ZigbeeDataType(data_value.ID), data_value.value)})

   local zclh = zcl_messages.ZclHeader({
     cmd = data_types.ZCLCommandId(write_attribute.WriteAttribute.ID)
   })
   local addrh = messages.AddressHeader(
       zb_const.HUB.ADDR,
       zb_const.HUB.ENDPOINT,
       device:get_short_address(),
       device:get_endpoint(cluster_id.value),
       zb_const.HA_PROFILE_ID,
       cluster_id.value
   )
   local message_body = zcl_messages.ZclMessageBody({
     zcl_header = zclh,
     zcl_body = write_body
   })
   device:send(messages.ZigbeeMessageTx({
     address_header = addrh,
     body = message_body
   }))
 end


--- Analog input configuration

  local function analog_input_configure(self, device)
  --- enable analog and binary inputs
  print("Enable Analog Input >>>>>>>>>>>>>>>>>>>>>>>> config")

  local data_value = {value = true, ID = 0x10}
  if device:get_field("analog_Input_Enable") == "Disabled" then data_value = {value = false, ID = 0x10} end
  local cluster_id = {value = 0x000C}
  local attr_id = 0x0051
  write_attribute_function(device, cluster_id, attr_id, data_value)

  --configure analog input reports
  local min = 0x0001
  local max = 0x0020
  local change = 0x0001
  if device:get_field("analog_Input_Enable") == "Disabled" then
    min = 0xFFFF
    max = 0xFFFF
    change = 0xFFFF
  end
  print("Configure Analog Reports >>>>>>>>>>>>") 
  print (">>>> Analog Report Min=",min ,"Report Max=",max, "Report change=",change)
  local config =
  {
    cluster = 0x000C,
    attribute = 0x0103,
    minimum_interval = min,
    maximum_interval = max,
    reportable_change = change,
    data_type = data_types.Int16,
  }
  device:add_configured_attribute(config)
  device:add_monitored_attribute(config)
  
  --configure attribute 0x0104
  config =
  {
    cluster = 0x000C,
    attribute = 0x0104,
    minimum_interval = min,
    maximum_interval = max,
    reportable_change = change,
    data_type = data_types.Int16,
  }
  device:add_configured_attribute(config)
  device:add_monitored_attribute(config)

end


--- Binary Input Configuration
local function binary_input_configure(self, device)
  print("Enable Binary Input >>>>>>>>>>>>>>>>>>>>>>>> config")

  local data_value = {value = true, ID = 0x10}
  if device:get_field("binary_Input_Enable") == "Disabled" then data_value = {value = false, ID = 0x10} end
  local cluster_id = {value = 0x000F}
  local attr_id = 0x0051
  write_attribute_function(device, cluster_id, attr_id, data_value)

--- Cofigure reports analogic and binary inputs
  print("Configure Binary Reports >>>>>>>>>>>>>>>>>>>>>>>> config")

  device:send(device_management.build_bind_request(device, BINARY_INPUT_CLUSTER, self.environment_info.hub_zigbee_eui))

  if device:get_field("binary_Input_Enable") == "Enabled" then
    device:send(BasicInput.attributes.PresentValue:configure_reporting(device, 1, 30))
  else
    device:send(BasicInput.attributes.PresentValue:configure_reporting(device, 0xFFFF, 0xFFFF))
  end
end

--- Binary Output Configuration
local function binary_output_configure(self, device)
  print("Enable Binary Output >>>>>>>>>>>>>>>>>>>>>>>> config")
  local data_value = {value = true, ID = 0x10}
  --if device:get_field("binary_Output_Enable") == "Disabled" then data_value = {value = false, ID = 0x10} end
  local cluster_id = {value = 0x0010}
  local attr_id = 0x0051
  write_attribute_function(device, cluster_id, attr_id, data_value)

  print(">>>>>> Emit Binary Output",data_value)
  if device:get_field("binary_Output_Enable") == "Disabled" then data_value = {value = false, ID = 0x10} end
  cluster_id = {value = 0x0010}
  attr_id = 0x0055
  write_attribute_function(device, cluster_id, attr_id, data_value)

  --- Cofigure reports analogic and binary inputs
  print("Configure Binary OutputReports >>>>>>>>>>>>>>>>>>>>>>>> config")

  device:send(device_management.build_bind_request(device, BINARY_OUTPUT_CLUSTER, self.environment_info.hub_zigbee_eui))
  
  local min = 0x1
  local max = 0x00FF
  local change = 0x1

  local config =
  {
    cluster = 0x0010,
    attribute = 0x0055,
    minimum_interval = min,
    maximum_interval = max,
    reportable_change = change,
    data_type = data_types.Int16,
  }
  device:add_configured_attribute(config)
  device:add_monitored_attribute(config)

end

--- do configure device
local function do_configure(self,device)

  if device:get_field("binary_Input_Enable") == nil then device:set_field("binary_Input_Enable", "Enabled", {persist = true}) end
  device:emit_event(binary_Input_Enable.binaryInputEnable(device:get_field("binary_Input_Enable")))
  
  if device:get_field("binary_Output_Enable") == nil then device:set_field("binary_Output_Enable", "Enabled", {persist = true}) end
  device:emit_event(binary_Output_Enable.binaryOutputEnable(device:get_field("binary_Output_Enable")))

  if device:get_field("analog_Input_Enable") == nil then  device:set_field("analog_Input_Enable", "Enabled", {persist = true}) end
  device:emit_event(analog_Input_Enable.analogInputEnable(device:get_field("analog_Input_Enable")))

  if device:get_field("moisture_Water_Sensor") == nil then  device:set_field("moisture_Water_Sensor", 0, {persist = true}) end
  device:emit_event(moisture_Water_Sensor.moistureWaterSensor(device:get_field("moisture_Water_Sensor")))

-- configure temperature reports
  local maxTime = device.preferences.temMaxTime * 60
  local changeRep = device.preferences.temChangeRep * 100
  print ("Temperature maxTime y changeRep: ",maxTime, changeRep )
  device:send(device_management.build_bind_request(device, tempMeasurement.ID, self.environment_info.hub_zigbee_eui))
  device:send(tempMeasurement.attributes.MeasuredValue:configure_reporting(device, 60, maxTime, changeRep))

-- configure humidity reports
  maxTime = device.preferences.humiMaxTime * 60
  changeRep = device.preferences.humiChangeRep * 100
  print ("Humidity maxTime y changeRep: ",maxTime, changeRep )
  local config =
  {
    cluster = 0x0405,
    attribute = 0x0000,
    minimum_interval = 60,
    maximum_interval = maxTime,
    reportable_change = changeRep,
    data_type = data_types.Uint16,
  }
  device:add_configured_attribute(config)
  device:add_monitored_attribute(config)
  --device:send(device_management.build_bind_request(device, HumidityCluster.ID, self.environment_info.hub_zigbee_eui))
  --device:send(HumidityCluster.attributes.MeasuredValue:configure_reporting(device, 60, maxTime, changeRep))

-- configure pressure reports
  maxTime = device.preferences.pressMaxTime * 60
  changeRep = device.preferences.pressChangeRep * 10
  print ("Pressure maxTime y changeRep: ",maxTime, changeRep )
  device:send(device_management.build_bind_request(device, zcl_clusters.PressureMeasurement.ID, self.environment_info.hub_zigbee_eui))
  device:send(zcl_clusters.PressureMeasurement.attributes.MeasuredValue:configure_reporting(device, 60, maxTime, changeRep))

-- configure Illuminance reports
  maxTime = device.preferences.illuMaxTime * 60
  changeRep = math.floor(10000 * (math.log((device.preferences.illuChangeRep + 1), 10)))
  print ("Illuminance maxTime y changeRep: ",maxTime, changeRep )
  device:send(device_management.build_bind_request(device, zcl_clusters.IlluminanceMeasurement.ID, self.environment_info.hub_zigbee_eui))
  device:send(zcl_clusters.IlluminanceMeasurement.attributes.MeasuredValue:configure_reporting(device, 60, maxTime, changeRep))

--- Enable & Configure Reports binary inputs
  binary_input_configure(self, device)

-- Enable & Configure reports analog input
  analog_input_configure(self, device)

--- Enable Binary Output
  binary_output_configure(self, device)

end

-- preferences update
local function do_preferences(self, device)
  for id, value in pairs(device.preferences) do
    print("device.preferences[infoChanged]=", device.preferences[id], "preferences: ", id)
    local oldPreferenceValue = device:get_field(id)
    local newParameterValue = device.preferences[id]
     if oldPreferenceValue ~= newParameterValue then
      device:set_field(id, newParameterValue, {persist = true})
      print("<< Preference changed: name, old, new >>", id, oldPreferenceValue, newParameterValue)
      if  id == "temMaxTime" or id == "temChangeRep" then
        local maxTime = device.preferences.temMaxTime * 60
        local changeRep = device.preferences.temChangeRep * 100
        print ("Temp maxTime & changeRep: ", maxTime, changeRep)
        device:send(device_management.build_bind_request(device, tempMeasurement.ID, self.environment_info.hub_zigbee_eui))
        device:send(tempMeasurement.attributes.MeasuredValue:configure_reporting(device, 60, maxTime, changeRep))
      elseif id == "humiMaxTime" or id == "humiChangeRep" then
        local maxTime = device.preferences.humiMaxTime * 60
        local changeRep = device.preferences.humiChangeRep * 100
        print ("Humidity maxTime & changeRep: ", maxTime, changeRep)
        device:send(device_management.build_bind_request(device, HumidityCluster.ID, self.environment_info.hub_zigbee_eui))
        device:send(HumidityCluster.attributes.MeasuredValue:configure_reporting(device, 60, maxTime, changeRep))
      elseif id == "pressMaxTime" or id == "pressChangeRep" then
        local maxTime = device.preferences.pressMaxTime * 60
        local changeRep = device.preferences.pressChangeRep * 10
        print ("Press maxTime & changeRep: ", maxTime, changeRep)
        device:send(device_management.build_bind_request(device, zcl_clusters.PressureMeasurement.ID, self.environment_info.hub_zigbee_eui))
        device:send(zcl_clusters.PressureMeasurement.attributes.MeasuredValue:configure_reporting(device, 60, maxTime, changeRep))
      elseif id == "illuMaxTime" or id == "illuChangeRep" then
        local maxTime = device.preferences.illuMaxTime * 60
        local changeRep = math.floor(10000 * (math.log((device.preferences.illuChangeRep + 1), 10)))
        print ("Illumin maxTime & changeRep: ", maxTime, changeRep)
        device:send(device_management.build_bind_request(device, zcl_clusters.IlluminanceMeasurement.ID, self.environment_info.hub_zigbee_eui))
        device:send(zcl_clusters.IlluminanceMeasurement.attributes.MeasuredValue:configure_reporting(device, 60, maxTime, changeRep))  
      end
    end
  end
end


--- temperature event handler
local function temp_attr_handler(self, device, tempvalue, zb_rx)
  tempMeasurement_defaults.temp_attr_handler(self, device, tempvalue, zb_rx)
end

-- attributte handler Atmospheric pressure
local pressure_value_attr_handler = function (driver, device, value, zb_rx)

  -- save previous pressure  and time values
  if device:get_field("last_value") == nil then device:set_field("last_value", value.value, {persist = true}) end
  local last_value = device:get_field("last_value")
  if device:get_field("last_value_time") == nil then device:set_field("last_value_time", (os.time() - (device.preferences.pressMaxTime * 60)) , {persist = true}) end
  local last_value_time = device:get_field("last_value_time")
  
  local kPa = math.floor (value.value / 10)
  
  --- emmit only events for >= device.preferences.pressChangeRep or device.preferences.pressMaxTim
  if math.abs(value.value - last_value) >= device.preferences.pressChangeRep * 10 or (os.time() - last_value_time) + 20 >= (device.preferences.pressMaxTime * 60) then
    device: emit_event (capabilities.atmosphericPressureMeasurement.atmosphericPressure ({value = kPa, unit = "kPa"}))

    -- emit even for custom capability in mBar
    local mBar = value.value
    device:emit_event(atmos_Pressure.atmosPressure(mBar))

    -- save emitted pressure value
    device:set_field("last_value", value.value, {persist = true})
    device:set_field("last_value_time", os.time(), {persist = true})
  end
end


---humidity_attr_handler
local function humidity_attr_handler(driver, device, value, zb_rx)

  -- save previous humidity and time values
  if device:get_field("last_humidity") == nil then device:set_field("last_humidity", value.value, {persist = true}) end
  local last_humidity = device:get_field("last_humidity")
  if device:get_field("last_humidity_time") == nil then device:set_field("last_humidity_time", (os.time() - (device.preferences.humiMaxTime * 60)) , {persist = true}) end
  local last_humidity_time = device:get_field("last_humidity_time")

  --- emmit only events for >= device.preferences.humChangeRep or device.preferences.humMaxTime
  if math.abs(value.value - last_humidity) >= device.preferences.humiChangeRep * 100 or (os.time() - last_humidity_time) + 20 >= (device.preferences.humiMaxTime * 60) then  
    device:emit_event_for_endpoint(zb_rx.address_header.src_endpoint.value, capabilities.relativeHumidityMeasurement.humidity(utils.round(value.value / 100.0)))
  
    -- save emitted pressure value
    device:set_field("last_humidity", value.value, {persist = true})
    device:set_field("last_humidity_time", os.time(), {persist = true})
  end
end

---illuminance_measurement_defaults
local function illuminance_measurement_defaults(driver, device, value, zb_rx)
  --local lux_value = math.floor(math.pow(10, (value.value - 1) / 10000))  --- defualt librarie edge lua
  local lux_value = math.floor(10 ^ ((value.value - 1) / 10000))
  device:emit_event_for_endpoint(zb_rx.address_header.src_endpoint.value, capabilities.illuminanceMeasurement.illuminance(lux_value))
end

---analog_adc_Input_Handler
local function analog_adc_Input_Handler(self,device,value)

 if device:get_field("analog_Input_Enable") == "Enabled" and last_vdd > 0 then
  print(" Analog Value ADC >>>>>>>>>>>", value.value)
  local volts1 = (value.value * last_vdd) / 0x1FFF
  local volts = tonumber(string.format("%.2f", volts1))

  --Detect water_Sensor state
  local waterSensorState = "Dry"
  if volts <= device.preferences.wetLevel then
    waterSensorState = "Wet"
  end

  if device:get_field("last_water_state") == nil then device:set_field("last_water_state", waterSensorState, {persist = true}) end
  if device:get_field("last_volts") == nil then device:set_field("last_volts", 0, {persist = true}) end
  print(">>>> Volts =", volts,">>>> last_volts=", device:get_field("last_volts"))
  print (">>> Volts- last_volts =", math.abs(volts - device:get_field("last_volts")))

   if math.abs(volts - device:get_field("last_volts")) >= device.preferences.voltsRepChange / 10 or device:get_field("last_water_state") ~= waterSensorState then
    device:emit_event(capabilities.voltageMeasurement.voltage(volts))

    device:set_field("last_volts", volts, {persist = true})
    device:set_field("last_water_state", waterSensorState, {persist = true})

    --Emit water_Sensor event
    if waterSensorState == "Dry" then
      device:emit_event_for_endpoint("main", capabilities.waterSensor.water.dry())
    else
      device:emit_event_for_endpoint("main", capabilities.waterSensor.water.wet())
    end
   
    --- calculate and emit moisture_Water_Sensor
    local volts_round = tonumber(string.format("%.1f", volts))
    local moisture_Sensor = (((device.preferences.voltsWetLevel0 - volts_round) + 0.001) / (device.preferences.voltsWetLevel0 - device.preferences.voltsWetLevel100)) * 100
    moisture_Sensor = math.floor(moisture_Sensor)
    if moisture_Sensor >= 100 then moisture_Sensor = 100 end
    if moisture_Sensor <= 0 then moisture_Sensor = 0 end
    device:set_field("moisture_Water_Sensor", moisture_Sensor, {persist = true})
    device:emit_event(moisture_Water_Sensor.moistureWaterSensor(moisture_Sensor))
   end

  else

   device:emit_event_for_endpoint("main", capabilities.waterSensor.water.dry())
   device:emit_event(capabilities.voltageMeasurement.voltage(0))
   device:set_field("moisture_Water_Sensor", 0, {persist = true})
   device:emit_event(moisture_Water_Sensor.moistureWaterSensor(0))
  end
end

---analog_vdd_Input_Handler
local function analog_vdd_Input_Handler(self,device,value)

 if device:get_field("analog_Input_Enable") == "Enabled" then
  print(" Analog Value VDD>>>>>>>>>>>", value.value)
  last_vdd = (value.value * 3.45) / 0x1FFF
 else
  last_vdd = 0
 end
end

---binary_Input_Handler
local function binary_Input_Handler(self,device,value)

 if device:get_field("binary_Input_Enable") == "Enabled" then
  print(" Binary Value >>>>>>>>>>>", value.value)

  local binary_text = "Active"
  if value.value == false then binary_text = "Inactive" end
  if device:get_field("binary_text") == nil then device:set_field("binary_text", " ", {persist = true}) end
  if binary_text ~= device:get_field("binary_text") then
    device:set_field("binary_text", binary_text, {persist = true})
    if binary_text == "Active" then
      device:emit_event_for_endpoint("main", capabilities.motionSensor.motion.active())
    else
      device:emit_event_for_endpoint("main", capabilities.motionSensor.motion.inactive())
    end

  end
 else

  device:emit_event_for_endpoint("main", capabilities.motionSensor.motion.inactive())
 end
end

---- binary_Input_Enable_handler
local function binary_Input_Enable_handler(self, device, command)
  print("binary_Input_Enable", command.args.value)
  device:set_field("binary_Input_Enable", command.args.value, {persist = true})
  device:emit_event(binary_Input_Enable.binaryInputEnable(command.args.value))
  if command.args.value == "Disabled" then
    device:emit_event_for_endpoint("main", capabilities.motionSensor.motion.inactive())
  end

  binary_input_configure(self, device)
end

---binary_Output_Enable_handler
local function binary_Output_Enable_handler(self, device, command)
  print("binary_Output_Enable", command.args.value)
  device:set_field("binary_Output_Enable", command.args.value, {persist = true})
  device:emit_event(binary_Output_Enable.binaryOutputEnable(command.args.value))

  binary_output_configure(self, device)

end

---- analog_Input_Enable_handler
local function analog_Input_Enable_handler(self,device,command)
  print("analog_Input_Enable", command.args.value)
  device:set_field("analog_Input_Enable", command.args.value, {persist = true})
  device:emit_event(analog_Input_Enable.analogInputEnable(command.args.value))
  if command.args.value == "Disabled" then
    device:emit_event(capabilities.voltageMeasurement.voltage(0))
    device:set_field("last_volts", 0, {persist = true})
    device:emit_event_for_endpoint("main", capabilities.waterSensor.water.dry())
    device:set_field("moisture_Water_Sensor", 0, {persist = true})
    device:emit_event(moisture_Water_Sensor.moistureWaterSensor(0))

  end
  --- Analog input configure
  analog_input_configure(self, device)

end

----- moisture_Water_Sensor_handler
local function moisture_Water_Sensor_handler(self, device, command)
  print("moisture_Water_Sensor", command.args.value)
  device:emit_event(moisture_Water_Sensor.moistureWaterSensor(device:get_field("moisture_Water_Sensor")))
end

----- driver template ----------
local zigbee_temp_driver = {
  supported_capabilities = {
    capabilities.relativeHumidityMeasurement,
    capabilities.atmosphericPressureMeasurement,
    atmos_Pressure,
    analog_Input_Enable,
    binary_Input_Enable,
    binary_Output_Enable,
    moisture_Water_Sensor,
    capabilities.illuminanceMeasurement,
    --capabilities.battery,
  },
  lifecycle_handlers = {
    init = do_configure,
    infoChanged = do_preferences,
    driverSwitched = do_configure
  },  
  capability_handlers = {
    [binary_Input_Enable.ID] = {
      [binary_Input_Enable.commands.setBinaryInputEnable.NAME] = binary_Input_Enable_handler,
    },
    [analog_Input_Enable.ID] = {
      [analog_Input_Enable.commands.setAnalogInputEnable.NAME] = analog_Input_Enable_handler,
    },
    [binary_Output_Enable.ID] = {
      [binary_Output_Enable.commands.setBinaryOutputEnable.NAME] = binary_Output_Enable_handler,
    },
    [moisture_Water_Sensor.ID] = {
      [moisture_Water_Sensor.commands.setMoistureWaterSensor.NAME] = moisture_Water_Sensor_handler,
    },
  },
  zigbee_handlers = {
    attr = {
      [ANALOG_INPUT_CLUSTER] ={
        [ANALOG_INPUT_ADC_ATTR_ID] = analog_adc_Input_Handler,
        [ANALOG_INPUT_VDD_ATTR_ID] = analog_vdd_Input_Handler
      },
      [BasicInput.ID] = {
        [BasicInput.attributes.PresentValue.ID] = binary_Input_Handler
      },
      [HumidityCluster.ID] = {
        [HumidityCluster.attributes.MeasuredValue.ID] = humidity_attr_handler
      },
      [tempMeasurement.ID] = {
          [tempMeasurement.attributes.MeasuredValue.ID] = temp_attr_handler
      },
      [zcl_clusters.PressureMeasurement.ID] = {
          [zcl_clusters.PressureMeasurement.attributes.MeasuredValue.ID] = pressure_value_attr_handler
      },
      [zcl_clusters.IlluminanceMeasurement.ID] = {
        [zcl_clusters.IlluminanceMeasurement.attributes.MeasuredValue.ID] = illuminance_measurement_defaults
      }
    },
  },

}

--------- driver run ------
defaults.register_for_default_handlers(zigbee_temp_driver, zigbee_temp_driver.supported_capabilities)
local temperature = ZigbeeDriver("st-zigbee-temp", zigbee_temp_driver)
temperature:run()
