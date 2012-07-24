def stamp_version(version,jenkins=None):
    t_vars = { 'version': version, 'build': jenkins }

    f = open('./scripts/assets/version.template', 'r')    
    content = f.read() % t_vars
    f.close()

    f = open('./OpenTreeMap/OpenTreeMap/version.plist','w')
    f.write(content)
    f.flush()
