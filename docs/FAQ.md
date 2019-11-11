# The libreCMC FAQ

## What is libreCMC?

The libreCMC project provides replacement software for consumer-grade
routers in the form of a small GNU/Linux distro. The software and tools
that the project distributes allow users to take back control of
their devices from hardware manufactures. Because libreCMC is [Free
Software](http://www.gnu.org/philosophy/free-sw.en.html), users are
able to unlock the ability to control and breath new life into
devices the project supports.

## Why should I care?

In the light of recent events, it is more important now more than ever to fight
for the freedom to control the software that runs on a given device. Users
should have the freedom to control their devices, not the OEMs who originally
made the device. Since libreCMC is free software, users have total control over
what the software on their device is doing. This is important because it means
that the community can add new features, review what the software is doing and
make improvements that benefit the community as a whole.

## What devices does libreCMC work with?

The libreCMC project supports mostly consumer-grade router and a few other
embedded devices.  This list can be found on the Supported Hardware page. While
this list is not extensive, the libreCMC project has very strict requirements
for supporting devices. Some examples include:

* libreCMC has to be installable from stock firmware. In most cases, devices
have a complicated process or use of additional tools to replace the firmware /
software. The project will still consider some level of support if it does not
meet this requirement and meets all of the other requirements.

* The hardware can't require non-free software or binary blobs to work. Non-free
Software / Blobs are pieces of software where we (the community) does not have
the source code under a proper Free Software [1] license. Non-free Software and
blobs make supporting a device for any length of time a chore and usually
support evaporates when device vendors stop releasing new blobs / components.
If a device requires non-free software or blobs, the libreCMC project won't
support devices that can't meet this requirement.

* The device needs to have enough flash (storage) to work with. Sadly,
the issue of bloat in modern times is seen as a non-issue for many
software developers. While there are a lot of hardware that the
project would like to support, there are some devices that just simply
don't have enough flash. One of the long-term goals of the project is
to eventually support devices with limited flash. Right now, the
minimum requirement for libreCMC supported devices is 4M of flash,
depending on the features that are desired.

## Features

The libreCMC project's main focus is on consumer-grade routers and a
few other embedded devices. While libreCMC is based upon OpenWrt, the
project does not support all of the same features and tries to strike
a balance between functionality and bloat. The project *does not*
support the following:

* UPnP support: UPnP is a security nightmare and the project won't support it.

* Services / Applications that belong on their own machine or can't
run on 90% of targets : While it might be cool to run a particular
service or application on your router, it is usually is a bad
idea. Many of the devices that we support are not capable of running
such things because of a lack of processing power, flash or RAM.

## How often are releases made?

libreCMC releases incremental every 3 - 6 months, depending on if
there is a critical security or design flaw. The project tries to
maintain major or LTS (long Term Support) releases for about 2 years.

## How can I get started with libreCMC?

[Getting Started]() Page : WIP?

## How can I contribute to libreCMC?

Pull requests can be made or issues can be filed against the project's
[git](https://gogs.librecmc.org/libreCMC/libreCMC) repository.

Information about monetary contributions can be found on the project's
[contact](https://librecmc.org/contact.html) page.
