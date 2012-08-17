""" Fabric script to handle common iOS building tasks """
from fabric.api import local, lcd, abort

import os


def stamp_version(version, jenkins=None):
    """ Write out a version number and jenkins build

        Write out to plist that Xcode build tools will compile into
        the app """
    t_vars = {'version': version, 'build': jenkins}

    template_file = open('./scripts/assets/version.template', 'r')
    content = template_file.read() % t_vars
    template_file.close()

    template_file = open('./OpenTreeMap/OpenTreeMap/version.plist', 'w')
    template_file.write(content)
    template_file.flush()


def clone_skin_repo(skin, clone_dir=None, version=None, user=None):
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
    if "@" in skin:
        if version:
            abort("Specify version via @ or version but not both")

        (skin, version) = skin.split("@")

    if not skin:
        abort("You must specify a valid skin")

    if not version:
        print "[Warn] Version not specified. Using 'master'"
        version = 'master'

    if user:
        git_remote_path = 'ssh://%s@git.internal.azavea.com'\
                          '/git/Azavea_OpenTreeMap/%s.git'\
                          % (user, skin)
    else:
        git_remote_path = 'git://git.internal.azavea.com/'\
                          'git/Azavea_OpenTreeMap/%s.git'\
                          % skin

    if clone_dir:
        git_local_path = '%s/%s' % (clone_dir, skin)
    else:
        git_local_path = ''

    local('git clone -b %s "%s" "%s"' %
          (version, git_remote_path, git_local_path))


def install_skin(skin, user=None, version=None, clone_dir=None, 
                 force_delete=None):
    """ Install the given skin

    Optionally specify clone_dir to control where the repository
    will be cloned to. Default is one level above this one

    If the repository has already been checked out (i.e.
    <clone_dir>/<skin>/ios exists) then you only need to
    run this command with the 'skin' argument.

    For details about the other arguments checkout `clone_skin_repo`

    Set 'force_delete' to True to delete any previous repos
    """
    if not clone_dir:
        clone_dir = '../'

    git_clone_path = '%s/%s' % (clone_dir, skin)

    if force_delete:
        local('rm -rf "%s"' % git_clone_path)

    if not os.path.exists('%s/ios' % git_clone_path):
        clone_skin_repo(skin, clone_dir, version, user)
        local('git clone '
              '"ssh://%s@git.internal.azavea.com/'
              'git/Azavea_OpenTreeMap/%s.git" '
              '"%s/%s"' % (user, skin, clone_dir, skin))

    with lcd('OpenTreeMap/OpenTreeMap'):
        local('rm -f skin')
        local('ln -s "../../%s/ios" skin' % git_clone_path)
        
