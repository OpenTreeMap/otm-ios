# OpenTreeMap for iOS

## Getting Started

### Service Dependencies

OpenTreeMap for iOS has 2 major web service dependencies:

  - An OpenTreeMap web application and ecobenefits service installation
  - An OpenTreeMap tiler installation

The source code for these services is available is available on Github:

- https://github.com/OpenTreeMap/otm-core
- https://github.com/OpenTreeMap/otm-ecoservice
- https://github.com/OpenTreeMap/otm-tiler


### Configuration files

The iOS application requires three configuration files:

* `OpenTreeMap/OpenTreeMap.entitlements`
* `OpenTreeMap/OpenTreeMap-Info.plist`
* `OpenTreeMap/skin/Implementation.plist`

This repository contains templates for all three, and a
[Fabric](http://www.fabfile.org/) command for generating
`OpenTreeMap-Info.plist`.

#### OpenTreeMap-Info.plist

This file can be generated with the following command, substituting
a unique application name and bundle ID.

    $ fab create_info_plist:app_name={app name},bundle_id={bundle id}

#### Implementation.plist

The template is available at `OpenTreeMap/skin/Implementation.plist.template`

Here is a description of the template variables within the file that
need to be replaced.

##### accesskey

Required.

The public portion of a valid OpenTreeMap API key that appears as a
query string argument in all API requests.

##### apiserver

Required.

The root URL of an OpenTreeMap installation.

##### apiversion

Required.

The version of OpenTreeMap API being used by the iOS
application. Should have the format "v4".

##### environment

Optional.

The environment name for messages logged to [Rollbar](https://rollbar.com/).

##### mapviewtitle

Optional.

The title of the main map view navigation controller.

##### reportemail

Required.

The email address to which inappropriate content reports are sent.

##### rollbar_client_access_token

Optional.

The token used to connect to and log messages in [Rollbar](https://rollbar.com/).

##### secretkey

Required.

The private portion of a valid API key used to sign all API requests.

##### splashdelay

Optional.

The splash screen image appears for this  minimum number of seconds.

##### tileserver

Required.

The root URL of the OpenTreeMap tiler service connected to the same
database as the application specified by `apiurl`.

##### urlname

Optional.

This is set to the `url_name` of an instance, the iOS application
will only connect show that instance. Otherwise the iOS application
will show a list of all available instances for the user to choose
from.

#### OpenTreeMap.entitlements

A template for this file is available at `OpenTreeMap/OpenTreeMap.entitlements.template`.

The `app_id` variable should be replaced with a unique
[App ID](https://developer.apple.com/library/ios/documentation/General/Conceptual/DevPedia-CocoaCore/AppID.html).


### Images and Other Content

This repository contains placeholder images for the user interface
widgets, icons, and splash screens, along with a default `about.html`
page. These should be replaced with your own content.




## USDA Grant

Portions of OpenTreeMap are based upon work supported by the National Institute of Food and Agriculture, U.S. Department of Agriculture, under Agreement No. 2010-33610-20937, 2011-33610-30511, 2011-33610-30862 and 2012-33610-19997 of the Small Business Innovation Research Grants Program. Any opinions, findings, and conclusions, or recommendations expressed on the OpenTreeMap website are those of Azavea and do not necessarily reflect the view of the U.S. Department of Agriculture.




## License

OpenTreeMap is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

OpenTreeMap is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with OpenTreeMap.  If not, see <http://www.gnu.org/licenses/>.
