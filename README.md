# OpenTreeMap for iOS

## Getting Started

OpenTreeMap for iOS has 2 major dependencies:

  - An OpenTreeMap web application installation
  - A "skin," which is a set of images and configurations files

The [source](https://github.com/azavea/OpenTreeMap) for the OpenTreeMap web application can be found [here](https://github.com/azavea/OpenTreeMap).

## Installation

### Download Skin

A default skin can be downloaded using the [Fabric](http://docs.fabfile.org/) script included with the OpenTreeMap for iOS source.

    $ fab install_skin
    $ fab create_info_plist:app_name={app name},app_id={app id}

The [default skin](https://github.com/azavea/OpenTreeMap-iOS-skin) is
also available.

### Install CocoaPods

If you don't already have it on your machine, install
[CocoaPods](http://cocoapods.org). Then execute `pod install` from a
command prompt.

    $ pod install

USDA Grant
---------------
Portions of OpenTreeMap are based upon work supported by the National Institute of Food and Agriculture, U.S. Department of Agriculture, under Agreement No. 2010-33610-20937, 2011-33610-30511, 2011-33610-30862 and 2012-33610-19997 of the Small Business Innovation Research Grants Program. Any opinions, findings, and conclusions, or recommendations expressed on the OpenTreeMap website are those of Azavea and do not necessarily reflect the view of the U.S. Department of Agriculture.

License
---------------

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
