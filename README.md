# OpenTreeMap for iOS

## Getting Started

OpenTreeMap for iOS has 2 major dependencies:

  - An OpenTreeMap web application installation
  - A "skin," which is a set of images and configurations files

The source for the OpenTreeMap web application is available on github

<a href="https://github.com/azavea/OpenTreeMap">https://github.com/azavea/OpenTreeMap</a>

A default skin can be downloaded using the Fabric (http://docs.fabfile.org/) script included with the OpenTreeMap for iOS source.

    $ fab install_skin
    $ fab create_info_plist:app_name={app name},app_id={app id}

The default skin may also be found on github

<a href="https://github.com/azavea/OpenTreeMap-iOS-skin">https://github.com/azavea/OpenTreeMap-iOS-skin</a>

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
