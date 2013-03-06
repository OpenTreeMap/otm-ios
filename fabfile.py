""" Fabric script to handle common iOS building tasks """
from fabric.api import local, lcd, abort, cd, run

import os
import tempfile

def resign_for_distribution(ipa, dist_profile, adhoc_profile, sign_name, appid_prefix, appid_suffix):
    local('unzip "%s.ipa"' % ipa)
    app_name = os.listdir('Payload')[0]

    def sign_with_profile(p, n):
        entfile = "Payload/%s/OpenTreeMap.entitlements" % app_name
        entsh = open(entfile)
        ents = entsh.read()
        entsh.close()

        ents = ents.replace("$(AppIdentifierPrefix)",appid_prefix + ".")
        ents = ents.replace("$(AppIdentifierSuffix)", "." + appid_suffix)

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

def create_info_plist(app_name, app_id, version='1.0',path=''):
    template_path = os.path.join(path, 'OpenTreeMap/OpenTreeMap-Info.plist.template')
    output_path = os.path.join(path, 'OpenTreeMap/OpenTreeMap-Info.plist')
    infoplist = open(template_path).read()
    infoplist = infoplist % { "app_name": app_name, "app_id": app_id, "version": version}

    f = open(output_path, 'w')
    f.write(infoplist)
    f.flush()
    f.close()

def convert_choices(choices_py,choices_plist):
    globs = {}
    execfile(choices_py, globs)
    choices = globs['CHOICES']

    hippie_xml = """<?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>"""

    for (ch, vals) in choices.iteritems():
        hippie_xml += """
        <key>%s</key>
        <array>\n""" % ch

        for (value, txt) in vals:
            hippie_xml += """
                <dict>
                        <key>key</key>
                        <string>%s</string>
                        <key>type</key>
                        <string>int</string>
                        <key>value</key>
                        <string>%s</string>
                </dict>\n""" % (value,txt)

        hippie_xml += "        </array>\n"

    hippie_xml += "</dict>\n"
    hippie_xml += "</plist>"

    f = open(choices_plist, 'w')
    f.write(hippie_xml)
    f.flush()
    f.close()



def clone_skin_repo(skin=None, clone_dir=None, version=None, user=None):
    """ Clone a skin repo

    Require arguments:
    skin - Name of the skin to download (Greenprint, Philadelphia, etc)
    version - Skin version to download (v1.1, git commit hash, etc)

    Note, you can specify the skin and the version together:
    clone_skin_repo(skin='Philadelphia@v1.2')

    Optional Arguments:
    clone_dir - Directory to clone to. If empty the clone will go into
                the current directory
    user - Specify a user to download via ssh, otherwise download
           public git

    """
    if skin and "@" in skin:
        if version:
            abort("Specify version via @ or version but not both")

        (skin, version) = skin.split("@")

    if not version:
        print "[Warn] Version not specified. Using 'master'"
        version = 'master'

    if user:  # If user is specified we are cloning an Azavea internal repository
        git_remote_path = 'ssh://%s@git.internal.azavea.com'\
                          '/git/Azavea_OpenTreeMap/%s.git'\
                          % (user, skin)
    elif skin:  # If skin is specified we are cloning an Azavea internal repository
        git_remote_path = 'git://git.internal.azavea.com/'\
                          'git/Azavea_OpenTreeMap/%s.git'\
                          % skin
    else:
        git_remote_path = 'https://github.com/azavea/OpenTreeMap-iOS-skin.git'

    if clone_dir and skin:
        git_local_path = '%s/%s' % (clone_dir, skin)
    elif clone_dir:
        git_local_path = '%s/%s' % (clone_dir, 'MobileSkin')
    else:
        git_local_path = 'MobileSkin'

    local('git clone -b %s "%s" "%s"' %
          (version, git_remote_path, git_local_path))


def package(skin=None, user=None, version=None,
            app_name="git-snapshot", app_ver="git-snapshot", app_id="com.company.otm"):
    """
    Package a skinned up implementation for deployment based on
    the current commit in this directory.

    This method creates a fresh clone, installs the skin, and
    generates a tarball. In particular, it *ignores* any extra
    files in the directory (such as private keys or config files)
    """
    temp_dir = tempfile.mkdtemp(prefix='fios_tmp')
    clone_dir = os.path.join(temp_dir, 'otmios')
    skin_clone_dir = os.path.join(temp_dir, 'skins')

    git_path = os.path.dirname(__file__)

    git_rev = local('git rev-parse HEAD', capture=True)

    with lcd(temp_dir):
        local('git clone "%s" "%s"' % (git_path, clone_dir))

    with lcd(clone_dir):
        local('git reset --hard %s' % git_rev)
        install_skin(skin, user, version, skin_clone_dir,
                     otm_dir=os.path.join(clone_dir,"OpenTreeMap"),
                     copy_instead_of_link=True)

    create_info_plist(app_name, app_id, app_ver,path=clone_dir)

    with lcd(temp_dir):
        local('tar -czf otmios.tar.gz otmios')

    local('mv "%s" "%s"' % (os.path.join(temp_dir,'otmios.tar.gz'), git_path))
    local('rm -rf "%s"' % temp_dir)


def install_skin(skin=None, user=None, version=None, clone_dir=None,
                 force_delete=None, copy_instead_of_link=False, otm_dir=None):
    """
    Install the given skin

    Optionally specify clone_dir to control where the repository
    will be cloned to. Default is one level above this one

    If the repository has already been checked out (i.e.
    <clone_dir>/<skin>/ios exists) then you only need to
    run this command with the 'skin' argument.

    For details about the other arguments checkout `clone_skin_repo`

    Set 'force_delete' to True to delete any previous repos
    """
    if not clone_dir:
        clone_dir = '..'

    if not otm_dir:
        otm_dir = 'OpenTreeMap'

    if skin:
        git_clone_path = '%s/%s' % (clone_dir, skin)
    else:
        git_clone_path = '%s/MobileSkin' % clone_dir

    if os.path.isabs(git_clone_path):
        ios_dir_path = os.path.join(git_clone_path, "ios")
    else:
        ios_dir_path = os.path.join("..", git_clone_path, "ios")

    if force_delete:
        local('rm -rf "%s"' % git_clone_path)

    if not os.path.exists('%s/ios' % git_clone_path):
        clone_skin_repo(skin, clone_dir, version, user)

    with lcd(otm_dir):
        local('rm -f skin')
        if copy_instead_of_link:
            local('cp -r "%s" skin' % ios_dir_path)
        else:
            local('ln -s "%s" skin' % ios_dir_path)

    with lcd(otm_dir):
        local('rm -f "Default.png" "Default@2x.png" '\
              '"Icon.png" "Icon@2x.png" "Icon-72.png" "Icon-72@2x.png"')
        local('cp "%s/images/splash_screen.png" '\
              'Default.png' % ios_dir_path)
        local('cp "%s/images/splash_screen@2x.png" '\
              '"Default@2x.png"' % ios_dir_path)
        local('cp "%s/icons/iphone_app-icon.png" '\
              'Icon.png' % ios_dir_path)
        local('cp "%s/icons/iphone_app-icon@2x.png" '\
              '"Icon@2x.png"' % ios_dir_path)
        local('cp "%s/icons/ipad_app-icon.png" '\
              'Icon-72.png' % ios_dir_path)
        local('cp "%s/icons/ipad_app-icon@2x.png" '\
              'Icon-72@2x.png' % ios_dir_path)

    convert_choices("%s/../choices.py" % ios_dir_path, os.path.join(otm_dir, "Choices.plist"))
