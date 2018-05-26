#/bin/bash
echo on

# check this doc: http://wiki.bash-hackers.org/howto/getopts_tutorial
while getopts ":d:u:p:" opt; do
  case $opt in
    d) database="$OPTARG"
    ;;
    u) user="$OPTARG"
    ;;
    p) password="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

# 0=true
valid=true

if [[ -z "${database// }" ]] 
then
	valid=false
	echo -d option is required. 
fi

if [[ -z "${user// }" ]] 
then
	valid=false
	echo -u option is required. 
fi

if [[ -z "${password// }" ]] 
then
	valid=false
	echo -p option is required. 
fi

if ( ! $valid )
then
	exit 1
fi

mongo << EOF
server = new Mongo("localhost:27017");
var databaseList = [{'db':'$database', 'user':'$user', 'pwd':'$password'}];          
databaseList.forEach(function(database) {
   db = server.getDB(database.db);
   db.dropUser(database.user);
   db.createUser({user:database.user, pwd:database.pwd, roles:["readWrite", "dbAdmin", "userAdmin"]});
});
exit;
EOF