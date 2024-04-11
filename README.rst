coreUnrealAutomaticMode
=======================

This is a Sample project to be used with coreDS Unreal and Unreal Engine 5. You can request a free trial at https://www.ds.tools/contact-us/trial-request/

coreDS Unreal must already be installed and activated to use this project. Please make sure the coreDS Unreal plugin is enabled.

This sample is compatible with the Unreal Engine 5+. A version compatible with UE4.24+ can be found in a different branch.

This sample showcases the Automatic Object Management mode. The Automatic Mode manages the complete life-cycle of discovered objects allowing an easy way to receive information from DIS or HLA. You can add receive and send DIS/HLA objects within a few minutes.

The Sample project uses the following coreDS concepts:

-  Connect
-  Disconnect
-  Send Update Object (send EntityStatePDU or UpdateAttributeValues,
   DiscoverObjectInstance)
-  Receive Update Object (Receive EntityStatePDU or
   UpdateAttributeValues)
-  Delete Objects (EntityStatePDU timeout or RemoveObjectInstance)

Runtime commands:

-  Pressing K will stop the connection and then open the configuration selection window. This allows to change from one distributed simulation protocol to the other without having to close the application.

Getting started
---------------

The first step is to configure coreDS Unreal to enable the Automatic Mode.

You can find that configuration from Edit->Project Settings->coreDS Unreal

.. image:: Doc/Images/AutomaticModeSettings.png
   :alt: Plugin Configuration Screenshot

Note the “UniqueIdentifier” field. We will come back to this later. For now, please note this field is a regex string. When the “UniqueIdentier” matches, the corresponding object is spawned. The first valid match will be used so you have to be careful to place your higher priority match at the beginning.

For each object, you can enable/disable collisions and physics. We recommend leaving the collision and physics disabled at first and enabling them afterwards when you can confirm the objects are spawned correctly.

In this particular example, everything matching EntityType 3.x.x.x.x.x.x will spawn a FirstPersonCharter object and everything matching EntityType 2.x.x.x.x.x.x will spawn a FirstPersonProjectile.

The two objects are also configurated to send their position via DIS/HLA when spawned (configuration is shown below)

The complete object life-cycle is managed by coreDS Unreal, including DIS Keep-alive updates. Connect and disconnect will also be taken care of automatically.

coreDS Unreal supports dead reckoning. You can enable it from the Plugin configuration Window by checking the “Enable Dead reckoning” box.

For DR to work properly it must first be activated and the DR properties must be correctly mapped (see below)

The next step is to configure an actual connection with a Distributed Simulation protocol. coreDS supports HLA (High-Level Architecture)and DIS (Distributed Interaction Simulation).

Special note to HLA Users
~~~~~~~~~~~~~~~~~~~~~~~~~

HLA can directly subscribe to very specific object classes without having to use a separate object type identification mechanism. coreDS Unreal provides two additional mechanisms to HLA users: You can also use the ObjectType (complete FOM denomination, HLAobjectRoot.BaseEntity…) or the Object Entity Name as the UniqueIdentifier. This allows to either generate actors directly based on the corresponding HLA Object Type or spawn a particular object based on its unique name (both mechanisms can’t be used at the same time; if you need to distinguish a particular object out of a group, please use the BluePrint interface).

.. image:: ./Doc/Images/HLAOtherProperties.png
   :alt: HLA Other Properties

When configuring an HLA connection, you can link the UniqueIdentifier property to the “Object Class Name” or the “Object Instance Name”.

The “Object Class Name” contains the value of the GetObjectClassName() function.

The “Object Instance Name” contains the value of the instance name, as received via the DiscoverObjectInstance callback.

You can open the configuration window either by running the game or by clicking on the coreDS toolbar button.

This sample comes with 4 pre-configured settings:
   DIS_Player1: DIS v6
   DIS_Player2: DIS v6
   HLA_Player1: HLA 1516e with RPRFOM 2.0
   HLA_Player2: HLA 1516e with RPRFOM 2.0

.. image:: Doc/Images/ConfigurationSelection.png
   :alt: Plugin ConfigurationSelection Screenshot

Let’s take a look at each configuration.

(Directly jump to the `HLA configuration <#hla>`__)

Distributed Interactive Simulation (DIS)
----------------------------------------

For both configurations, it is important to configure the Configured Network Adapter. Click on the dropbox and select your active Network Adapter.

.. image:: Doc/Images/DISConnectionConfiguration.png
   :alt: Plugin DISConnectionConfiguration Screenshot

Even if DIS does not explicitly support Subscription, coreDS supports incoming filtering. First, we must let coreDS know that we want to receive the EntityStatePDU. Publish PDUs that you want to send and subscribe to those you want to receive.

.. image:: Doc/Images/DIS_Receiver_PubSub.png
   :alt: Plugin DIS_Receiver_PubSub Screenshot

Receiving
~~~~~~~~~

Then comes the Mapping configuration. Since we are in a receiver, we care about the “Mapping In”

The first step is to Map a Local Object to a Protocol Object. As you see, an “Automatic Object” is listed in the “+” list. You can then link the “Automatic Object” to “Entity State PDU”.

.. image:: Doc/Images/DISMappingIn_ObjectMapping.png
   :alt: Plugin DISMappingIn_ObjectMapping Screenshot

Then you must map the local properties to the protocol properties. Since we are in a receiving mode, we only care about the values we are interested in. In our case, we want to send back to Unreal the Location and the Orientation. When using the Automatic Mode, it is really important to set a “UniqueIdentifier”. The “UniqueIdentifier” can be anything meaning you could assign it to Marking to discriminate based on the object name. In most cases, we use the EntityType. To do so, set an “On Data Received” script to “EntityType”. You can select the script “UseAsUniqueIdentifier.lua”.

.. image:: Doc/Images/DISMappingIn_WithChoice.png
   :alt: Plugin DISMappingIn_WithChoice Screenshot

Dead Reckoning
~~~~~~~~~~~~~~

If DR is enabled, you must map the DR properties correctly like this:

.. image:: Doc/Images/DISMappingIn_DR.png
   :alt: Plugin DISMappingIn_DR Screenshot

Finally, we are receiving coordinates in Geocentric format, which Unreal doesn’t like. We could convert the coordinates from within Unreal but by doing so, it will be harder to switch to a different Distributed Simulation Protocol. To keep all the configurations runtime, we use the embedded Lua scripting engine to convert from Geocentric to flat coordinates centred around a given Lat/Long.

.. image:: Doc/Images/DISMappingIn.png
   :alt: Plugin DISMappingIn Screenshot

Below is the script that converts from Geocentric to local coordinates. Scripts are located in /Config/Scripts

.. code-block:: lua

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
       --Convert lat/long to geocentric
       tempx, tempy, tempz = lla2ecef(referenceOffset_Lat , referenceOffset_Long , referenceOffset_Alt )

       DSimLocal.X = (tempx - DSimLocal.X)  -- offset to the local coordinates
       DSimLocal.Y = (tempy - DSimLocal.Y)
       DSimLocal.Z = (tempz - DSimLocal.Z)
   end

At this point, you are done. Depending on your plugin configuration, each time an EntityStatePdu is received, a new object will be spawned and its complete lifecycle will be handled by coreDS Unreal.

Sending
~~~~~~~

If there is an object that you want to publish to the network, you must add the “coreDS Sender Component” to that object or blueprint.

.. image:: Doc/Images/coreDSSenderComponentOnObject.png
   :alt: Plugin coreDS Sender Component Screenshot

Once the actor is added, you must set a valid ObjectType (all objects with the same object type will use the same mapping). In our particular case, we assigned a “Core DS Sender Component” to the FirstPersonCharacter" actor and the “FirstPersonProjectile” blueprint.

Then comes the Mapping configuration. Since we are in a Sender, we care about the “Mapping Out”

The first step is to Map a Local Object to a Protocol Object. As you see, the Names you defined during the component configuration are listed in the “+” list. You can then link the Local Object to a Protocol Object by using the dropbox next to the Object name.

Then you must map the local properties to the protocol properties. Since we are in a Sender mode, we must fill the complete structure. Static values can be set at this point. We will map Location and Orientation to local properties.

Finally, we are sending coordinations in local format, which DIS doesn’t like. We could convert the coordinates from within Unreal but by doing so, it will be harder to switch to a different Distributed Simulation Protocol. To keep all the configurations editable runtime, we use the embedded Lua scripting engine to convert from flat coordinates, centered around a given Lat/Long, to Geocentric. 

.. image:: Doc/Images/DISMappingOut.png
   :alt: Plugin DISMappingOut Screenshot

As for outgoing values, you must set a conversion script to convert from the local coordinates to geocentric coordinates. Scripts are located in /Content/coreDS/Scripts.

High-Level Architecture (HLA)
-----------------------------

For both configurations, it is important to configure the connection to the correct RTI.

.. image:: Doc/Images/HLAConnectionRTISettings.png
   :alt: Plugin HLAConnectionConfiguration Screenshot

coreDS-based products support a wide variety of RTI, HLA versions and binding types. It is important to select the correct RTI Settings combination. Although coreDS will try to inform you, at runtime, if the selected combination is invalid, this is not a failsafe process. An incorrect combination can lead to an unexpected crash. Do not hesitate to contact us if you are unsure about your configuration.

Publication and Subscription
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

In this particular sample, we published/subscribed to

HLAobjectRoot.BaseEntity.PhysicalEntity.Lifeform.Human, EntityType, EntityIdentifier and Spacial

.. image:: Doc/Images/HLA_Receiver_PubSub.png
   :alt: Plugin HLA_Receiver_PubSub Screenshot

Federate Parameters
~~~~~~~~~~~~~~~~~~~

The Federate parameters pane contains all the information required to create, join and configure a connection to the RTI.

.. image:: Doc/Images/HLAFederateSettings.png
   :alt: Plugin HLA Federate Settings Screenshot

Receiving
^^^^^^^^^

Then comes the Mapping configuration. Since we are in a receiver, we care about the “Mapping In”

The first step is to Map a Local Object to a Protocol Object. As you see, an “Automatic Object” is listed in the “+” list. You can then link the “Automatic Object” to “HLAobjectRoot.BaseEntity.PhysicalEntity.Lifeform.Human”.

.. image:: Doc/Images/HLAMappingIn_ObjectMapping.png
   :alt: Plugin HLAMappingIn_ObjectMapping Screenshot

Then you must map the local properties to the protocol properties. Since we are in a receiving mode, we only care about the values we are interested in. In our case, we want to send back to Unreal the Location and the Orientation. When using the Automatic Mode, it is really important to set a “UniqueIdentifier”. The “UniqueIdentifier” can be anything meaning you could assign it to Marking to discriminate based on the object name. In most cases, we use the EntityType. To do so, set an “On Data Received” script to “EntityType”. You can select the script “UseAsUniqueIdentifier.lua”.

.. image:: Doc/Images/HLAMappingIn_WithChoice.png
   :alt: Plugin HLAMappingIn_WithChoice Screenshot

Dead Reckoning
^^^^^^^^^^^^^^

If DR is enabled, you must map the DR properties correctly like this:

.. image:: Doc/Images/HLAMappingIn_DR.png
   :alt: Plugin DISMappingIn_DR Screenshot

Finally, we are receiving coordination in a Geocentric format, which Unreal doesn’t like. We could convert the coordinates from within Unreal but by doing so, it will be harder to switch to a different Distributed Simulation Protocol. To keep all the configurations editable at runtime, we use the embedded Lua scripting engine to convert from Geocentric to flat coordinates centred around a given Lat/Long.

.. image:: Doc/Images/HLAMappingIn.png
   :alt: Plugin DISMappingIn Screenshot

Below is the script that converts from Geocentric to local (ENU) coordinates. Scripts are located in /Config/Scripts

.. code-block:: lua

   angleConversions = require("angleConversions")
   require("ecef2lla")
   require("ReferenceLatLongAlt")

   function convertPositionFromHLA()

   --convert orientation
   latTemp, lonTemp, discard = ecef2lla(DSimLocal.WorldLocation.X,DSimLocal.WorldLocation.Y,DSimLocal.WorldLocation.Z)

   local lat = math.rad(latTemp)  --converting to rad because function requires rad
   local lon = math.rad(lonTemp)

   local psi =  DSimLocal.Orientation.Psi-- roll
   local theta = DSimLocal.Orientation.Theta--pitch
   local phi = DSimLocal.Orientation.Phi --yaw

   DSimLocal.Orientation.Psi =  angleConversions.getOrientationFromEuler(lat, lon, psi, theta)
   DSimLocal.Orientation.Theta = angleConversions.getPitchFromEuler(lat, lon, psi, theta)
   DSimLocal.Orientation.Phi = angleConversions.getRollFromEuler(lat, lon, psi, theta, phi)


   --- convert position
   DSimLocal.WorldLocation.X, DSimLocal.WorldLocation.Y,  DSimLocal.WorldLocation.Z = EcefToEnu(DSimLocal.WorldLocation.X, DSimLocal.WorldLocation.Y, DSimLocal.WorldLocation.Z, referenceOffset_Lat , referenceOffset_Long , referenceOffset_Alt )

   DSimLocal.WorldLocation.X = DSimLocal.WorldLocation.X
   DSimLocal.WorldLocation.Y = DSimLocal.WorldLocation.Y
   DSimLocal.WorldLocation.Z = DSimLocal.WorldLocation.Z

At this point, you are done. Depending on your plugin configuration, each time a Human is received, a new object will be spawned and its complete lifecycle will be handled by coreDS Unreal.

Sending
^^^^^^^

If there is an object that you want to publish to the network, you must add the “coreDS Sender Component” to that object or blueprint.

.. image:: Doc/Images/coreDSSenderComponentOnObject.png
   :alt: Plugin coreDS Sender Component Screenshot

Once the actor is added, you must set a valid ObjectType (all objects with the same object type will use the same mapping). In our particular case, we assigned a “Core DS Sender Component” to the FirstPersonCharacter" actor and the “FirstPersonProjectile” actor blueprint. An “ObjectType” is a unique string, with no relation to the naming convention of the distributed simulation system, used to identify a given object type in your simulator.

Then comes the Mapping configuration. Since we are in a Sender, we care about the “Mapping Out”

The first step is to Map a Local Object to a Protocol Object. As you see, the Names you defined during the component configuration are listed in the “+” list. You can then link the Local Object to a Protocol Object by using the dropbox next to the Object name.

Then you must map the local properties to the protocol properties. Since we are in a Sender mode, we must fill the complete structure. Static values can be set at this point. We will map Location and Orientation to local properties.

Finally, we are sending coordinations in local format, which the RPR-FOM doesn’t like. We could convert the coordinates from within Unreal but by doing so, it will be harder to switch to a different Distributed Simulation Protocol. To keep all the configurations editable at runtime, we use the embedded Lua scripting engine to convert from flat coordinates, centered around a given Lat/Long, to Geocentric.

.. image:: Doc/Images/HLAMappingOut.png
   :alt: Plugin HLAMappingOut Screenshot

As for outgoing values, you must set a conversion script to convert from the local coordinates to geocentric coordinates. Scripts are located in /Content/coreDS/Scripts.
