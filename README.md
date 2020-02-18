# coreUnrealAutomaticMode
This is a Sample project to be used with coreDS Unreal and the Unreal Engine 4. You can request a free trial on https://www.ds.tools/contact-us/trial-request/

coreDS Unreal must already be installed and activated in order to use this project. Please make sure the coreDS Unreal plugin is enabled.

This sample showcase the Automatic Object Management mode. The Automatic Mode management the complete life-cycle of discovered objects allowing an easy eay to receive information from DIS or HLA. You can add receive ans send DIS/HLA objects within a few minutes.

The Sample project uses the following coreDS concepts:

* Connect
* Disconnect
* Send Update Object (send EntityStatePDU or UpdateAttributeValues, DiscoverObjectInstance)
* Receive Update Object (Receive EntityStatePDU or UpdateAttributeValues)
* Delete Objects (EntityStatePDU timeout or RemoveObjectInstance)

Runtime commands:

* Pressing K will stop the connection then open the configuration selection window. This allows to change from one distributed simulation protocol to the other without having to close the application.

## Getting started
The first step is to configure coreDS Unreal to enable the Automatic Mode.

You can find that configuration from Edit->Project Settings->coreDS Unreal

![Plugin Configuration Screenshot](/Doc/Images/AutomaticModeSettings.png)

Note the "UniqueIdentifier" field. We will come back to this later. For now, please note this field is a regex string. When the "UniqueIdentier" matches, the corresponding object is spawned. The first valid match will be used so you have to be careful to place your higher priority match at the beginning.

For each object, you can enable/disable collisions and physics. We recommand leaving the collision and physics disable at first and enabling them afterwards when you can confirmed the objects are spawned correctly.

In this particular example, everything matching EntityType 3.x.x.x.x.x.x will spawn a FirstPersonCharter object and everything matching EntityType 2.x.x.x.x.x.x will spawn a FirstPersonProjectile.

The two objects are also configurated to send their position via DIS when spawned (configuration is shown below)

The complete object life-cycle is managed by coreDS Unreal, including DIS Keep-alive updates. Connect and disconnect will also be taken care of automatically.

# Dead Reckoning
coreDS Unreal supports dead reckoning. You can enable it from the Plugin configuration Window by checking the "Enable Deadreckoning" box.

In order for DR to works properly it must first be activated and the DR properties must be correctly mapped (see below)

Next step is to configure an actual connection with a Distributed Simulation protocol. coreDS supports HLA (High-Level Architecture)and DIS (Distributed Interaction Simulation).

You can open the configuration window either by running the game or by click on the coreDS toolbar button.
![Plugin coreDSToolboxMenu Screenshot](/Doc/Images/coreDSToolboxMenu.png)

This sample comes with 4 pre-configured settings:
* DIS_Player1: DIS v6
* DIS_Player2: DIS v6
* HLA_Player1: HLA 1516e with RPRFOM 2.0
* HLA_Player2: HLA 1516e with RPRFOM 2.0

![Plugin ConfigurationSelection Screenshot](/Doc/Images/ConfigurationSelection.png)

Let's take a look at each configuration.

### DIS
For both configurations, it is important to configure the Configured Network Adapter. Click on the dropbox and select your active Network Adapter.

![Plugin DISConnectionConfiguration Screenshot](/Doc/Images/DISConnectionConfiguration.png)

Even if DIS does not explicitly support Subscription, coreDS supports incoming filtering. First, we must let coreDS knows that we want to receive the EntityStatePDU. Publish PDUs that you want to send and subscribe to those you want to receive.

![Plugin DIS_Receiver_PubSub Screenshot](/Doc/Images/HLA_Receiver_PubSub.png)

#### Receiving
Then comes the Mapping configuration. Since we are in a receiver, we care about the "Mapping In"

The first step is to Map a Local Object to a Protocol Object. As you see, an "Automatic Object" is listed in the "+" list. You can then link the "Automatic Object" to "Entity State PDU".

![Plugin DISMappingIn_ObjectMapping Screenshot](/Doc/Images/DISMappingIn_ObjectMapping.png)

Then you must map the local properties to the protocol properties. Since we are in a receiving mode, we only care about the values we are interested in. In our case, we want to send back to Unreal the Location and the Orientation. When using the Automatic Mode, it is really important to set a "UniqueIdentifier". The "UniqueIdentifier" can be anything meaning you could assign it to Marking to discriminate based on the object name. In most cases, we use the EntityType. To do so, set a "On Data Received" script to "EntityType". You can select the script "UseAsUniqueIdentifier.lua".

![Plugin DISMappingIn_WithChoice Screenshot](/Doc/Images/DISMappingIn_WithChoice.png)

# Dead Reckoning
If DR is enabled, you must map the DR properties correctly like this:

![Plugin DISMappingIn_DR Screenshot](/Doc/Images/DISMappingIn_DR.png)

Finally, we are receiving coordinations in Geocentric format, which Unreal doesn't like. We could convert the coordinates from within Unreal but by doing so, it will be harder to switch to a different Distributed Simulation Protocol. To keep all the configuration are runtime, we use the embedded Lua scripting engine to convert from Geocentric to flat coordinates centered around a given Lat/Long.

![Plugin DISMappingIn Screenshot](/Doc/Images/DISMappingIn.png)

Below is the script that convert from Geocentric to local coordinates. Scripts are located in /Config/Scripts

```lua
require("lla2ecef")  -- include functions to convert from Lat/Log to geocentric
require("ReferenceLatLongAlt") -- Include the Center Lat/Long

lastPositionX = 0 -- Last received position, used by the Orientation conversion script
lastPositionY = 0
lastPositionZ = 0

function convertPositionFromDIS()  --same function name as the filename
    lastPositionX = DSimLocal.X
    lastPositionY = DSimLocal.Y
    lastPositionZ = DSimLocal.Z

    -- Since we are working over a fairly small part of the planet, we can assume a flat surface
    --convert lat/long to geocentric
    tempx, tempy, tempz = lla2ecef(referenceOffset_Lat , referenceOffset_Long , referenceOffset_Alt )

    DSimLocal.X = (tempx - DSimLocal.X)  -- offset to the local coordinates
    DSimLocal.Y = (tempy - DSimLocal.Y)
    DSimLocal.Z = (tempz - DSimLocal.Z)
end
```

At this point, you are done. Depending on your plugin configuration, each time an EntityStatePdu is received, a new object will be spawned and it's complete lifecycle will be handled by coreDS Unreal.

#### Sending
If there is a object that you want to publish to the network, you must add the "coreDS Sender Component" to that object or blueprint.

![Plugin coreDS Sender Component Screenshot](/Doc/Images/coreDSSenderComponentOnObject.png)

Once the actor is added, you must set a valid ObjectType (all object with the same object type will use the same mapping). In our particular case, we assigned a "Core DS Sender Component" to the FirstPersonCharacter" actor and to the "FirstPersonProjectile" blueprint.

Then comes the Mapping configuration. Since we are in a Sender, we care about the "Mapping Out"

The first step is to Map a Local Object to a Protocol Object. As you see, the Names you defined during the component configuration are listed in the "+" list. You can then link the Local Object to a Protocol Object by using the dropbox next to the Object name.

Then you must map the local properties to the protocol properties. Since we are in a Sender mode, we must fill the complete structure. Static values can be set at this point. We will map Location and Orientation to local properties.

Finally, we are sending coordinations in local format, which DIS doesn't like. We could convert the coordinates from within Unreal but by doing so, it will be harder to swith to a different Distributed Simulation Protocol. To keep all the configuration are runtime, we use the embededded Lua scripting engine to convert from flat coordinates, centered around a given Lat/Long, to Geocentric.

![Plugin DISMappingOut Screenshot](/Doc/Images/DISMappingOut.png)

As for outgoing values, you must set a conversion script to convert from the local coordinates to geocentric coordinates. Scripts are located in /Config/Scripts. 

### HLA
To be done. Concepts are similar and mapping pretty much the same.