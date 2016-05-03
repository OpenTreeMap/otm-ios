""" Fabric script to handle common iOS building tasks """
from fabric.api import local, lcd, abort, cd, run

import os
import tempfile

def resign_for_distribution(ipa, dist_profile, adhoc_profile, sign_name, appid_prefix, appid_suffix, switch_to_org=False):
    local('unzip "%s.ipa"' % ipa)
    app_name = os.listdir('Payload')[0]

    def sign_with_profile(p, n):
        entfile = "Payload/%s/OpenTreeMap.entitlements" % app_name
        entsh = open(entfile)
        ents = entsh.read()
        entsh.close()

        ents = ents.replace("$(AppIdentifierPrefix)",appid_prefix + ".")
        ents = ents.replace("$(AppIdentifierSuffix)", "." + appid_suffix)

        if switch_to_org:
            ents = ents.replace(".com.",".org.")

        entsh = open(entfile,'w')
        entsh.write(ents)
        entsh.close()

        local('rm -rf "Payload/%s/_CodeSignature" '\
              '"Payload/%s/CodeResources"' % (app_name, app_name))
        local('cp "%s" "Payload/%s/embedded.mobileprovision"' % (p, app_name))
        local('/usr/bin/codesign -f -vvv -s "%s" '
              '--entitlements "Payload/%s/OpenTreeMap.entitlements" '
              '--resource-rules "Payload/%s/ResourceRules.plist" '
              '-i "Payload/%s/embedded.mobileprovision" '
              '"Payload/%s"' % (sign_name, app_name,
                                app_name, app_name, app_name))
        local('zip -qr "%s.%s.ipa" Payload' % (ipa,n))

    sign_with_profile(dist_profile, 'dist')
    sign_with_profile(adhoc_profile, 'adhoc')

    local('rm -rf Payload')

def stamp_version(version, jenkins=None):
    """ Write out a version number and jenkins build

        Write out to plist that Xcode build tools will compile into
        the app """
    t_vars = {'version': version, 'build': jenkins}

    content = """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
        <key>version</key>
        <string>%(version)s</string>
    <key>build</key>
        <string>%(build)s</string>
</dict>
</plist>""" % t_vars

    template_file = open('./OpenTreeMap/version.plist', 'w')
    template_file.write(content)
    template_file.flush()

def create_info_plist(app_name, bundle_id, version='2.0.0', path=''):
    template_path = os.path.join(path, 'OpenTreeMap/OpenTreeMap-Info.plist.template')
    output_path = os.path.join(path, 'OpenTreeMap/OpenTreeMap-Info.plist')
    infoplist = open(template_path).read()
    infoplist = infoplist % { "app_name": app_name, "bundle_id": bundle_id, "version": version}

    f = open(output_path, 'w')
    f.write(infoplist)
    f.flush()
    f.close()
