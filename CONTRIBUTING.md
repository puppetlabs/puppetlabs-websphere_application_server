## General Notes

So you're a masochist, eh?

Development is being done for, and being tested with, WebSphere Application
Server Network Deployment.  The _Network Deployment_ part might be important.
You'll see mention of "Liberty Profile" around IBM's site, and that's not what
you're looking for.  The Network Deployment is the real deal - the big guy.

It includes Java version 1.6.

IBM HTTP Server (IHS) isn't technically part of WebSphere - this is a separate
download.  WebSphere does come with some hooks for it and plugins, but the
software itself is separate.

IBM software gets installed with "Installation Manager", which I've put into
a separate module. This is another typical stupid IBM tool.  It does have
a GUI or command-line tool.  We're using the CLI tool, obviously. All of the
packages below get installed using this tool, including "fixpacks" and stuff
like that.  It *is* queryable, but I haven't figured out how to get useful
enough information out of it.  You can install multiple instances of all this
stuff to different locations, and I can't figure out how to get the truly
unique instance info out of IM.

It seems that "response files" are favored among the community, for what it's
worth.  That said, related software to this module should support that.

### Must support multiple instances

This module needs to be able to manage multiple instances of WAS and IHS

### Vagrant

You can use Vagrant for development and testing if you get the software listed
below.

The use case is three nodes: DMGR, IHS, and app node(s).  Technically, you can
have all of these on a single node, though.

## Downloads

### Download link

You'll need an account.

[https://www14.software.ibm.com/webapp/iwm/web/reg/download.do?source=swerpws-wasnd85&S_PKG=500026211&S_TACT=109J87BW&lang=en_US&cp=UTF-8](https://www14.software.ibm.com/webapp/iwm/web/reg/download.do?source=swerpws-wasnd85&S_PKG=500026211&S_TACT=109J87BW&lang=en_US&cp=UTF-8)

You need:

* WebSphere Application Server Network Deployment
* IBM HTTP Server (IHS)
* IBM Web Server Plug-ins for WAS
* Installation Manager (separate module)

### Base Install

#### WebSphere Application Server Network Deployment Trial, Installation Manager Repository

IBM WebSphere Application Server Network Deployment Trial, Full Profile (Part 1 of 3)
`was.repo.8550.ndtrial_part1.zip`  (1.1G)

IBM WebSphere Application Server Network Deployment Trial, Full Profile (Part 2 of 3)
`was.repo.8550.ndtrial_part2.zip`  (1.1G)

IBM WebSphere Application Server Network Deployment Trial, Full Profile (Part 3 of 3)
`was`.repo.8550.ndtrial_part3.zip  (903M)

#### IBM HTTP Server for WebSphere Application Server, Installation Manager Repository

IBM HTTP Server for WebSphere Application Server (Part 1 of 2)
`was.repo.8550.ihs.ilan_part1.zip`  (976M)

IBM HTTP Server for WebSphere Application Server (Part 2 of 2)
`was.repo.8550.ihs.ilan_part2.zip`  (576M)

#### Web Server Plug-ins for WebSphere Application Server, Installation Manager Repository

Web Server Plug-ins for IBM WebSphere Application Server (Part 1 of 2)
`was.repo.8550.plg.ilan_part1.zip`  (961M)

Web Server Plug-ins for IBM WebSphere Application Server (Part 2 of 2)
`was.repo.8550.plg.ilan_part2.zip`  (696M)

### Fix Packs

Part of the development also involves supporting the application of "FixPacks"

You'll need the following (or a more current version):

__Application Server V8.5.5.4 local repository ZIP Files__

* 8.5.5-WS-WAS-FP0000004-part1.zip
* 8.5.5-WS-WAS-FP0000004-part2.zip

The same WAS fixpack also applies to IHS, the plug-ins, and Java.

__Main URL:__

[http://www-01.ibm.com/support/docview.wss?uid=swg24038539](http://www-01.ibm.com/support/docview.wss?uid=swg24038539)

##### 8.5.5-WS-WAS-FP0000004-part1.zip

[http://www-933.ibm.com/support/fixcentral/swg/quickorder?parent=ibm/WebSphere&product=ibm/WebSphere/WebSphere+Application+Server&release=All&platform=All&function=fixId&fixids=8.5.5-WS-WAS-FP0000004-part1&includeSupersedes=0&source=fc](http://www-933.ibm.com/support/fixcentral/swg/quickorder?parent=ibm/WebSphere&product=ibm/WebSphere/WebSphere+Application+Server&release=All&platform=All&function=fixId&fixids=8.5.5-WS-WAS-FP0000004-part1&includeSupersedes=0&source=fc)

##### 8.5.5-WS-WAS-FP0000004-part2.zip

[http://www-933.ibm.com/support/fixcentral/swg/quickorder?parent=ibm/WebSphere&product=ibm/WebSphere/WebSphere+Application+Server&release=All&platform=All&function=fixId&fixids=8.5.5-WS-WAS-FP0000004-part2&includeSupersedes=0&source=fc](http://www-933.ibm.com/support/fixcentral/swg/quickorder?parent=ibm/WebSphere&product=ibm/WebSphere/WebSphere+Application+Server&release=All&platform=All&function=fixId&fixids=8.5.5-WS-WAS-FP0000004-part2&includeSupersedes=0&source=fc)

[http://www-01.ibm.com/support/docview.wss?uid=swg24038539](http://www-01.ibm.com/support/docview.wss?uid=swg24038539)

#### Java 1.7

We also need an updated version of Java.

__IBM WebSphere SDK Java Technology Edition (Optional) V7.1.2.0 for Full Profile__

* 7.1.2.0-WS-IBMWASJAVA-part1.zip
* 7.1.2.0-WS-IBMWASJAVA-part2.zip

##### 7.1.2.0-WS-IBMWASJAVA-part1.zip

[http://www-933.ibm.com/support/fixcentral/swg/quickorder?parent=ibm/WebSphere&product=ibm/WebSphere/WebSphere+Application+Server&release=All&platform=All&function=fixId&fixids=7.1.2.0-WS-IBMWASJAVA-part1&includeSupersedes=0&source=fc](http://www-933.ibm.com/support/fixcentral/swg/quickorder?parent=ibm/WebSphere&product=ibm/WebSphere/WebSphere+Application+Server&release=All&platform=All&function=fixId&fixids=7.1.2.0-WS-IBMWASJAVA-part1&includeSupersedes=0&source=fc)

##### 7.1.2.0-WS-IBMWASJAVA-part2.zip

[http://www-933.ibm.com/support/fixcentral/swg/quickorder?parent=ibm/WebSphere&product=ibm/WebSphere/WebSphere+Application+Server&release=All&platform=All&function=fixId&fixids=7.1.2.0-WS-IBMWASJAVA-part2&includeSupersedes=0&source=fc](http://www-933.ibm.com/support/fixcentral/swg/quickorder?parent=ibm/WebSphere&product=ibm/WebSphere/WebSphere+Application+Server&release=All&platform=All&function=fixId&fixids=7.1.2.0-WS-IBMWASJAVA-part2&includeSupersedes=0&source=fc)
