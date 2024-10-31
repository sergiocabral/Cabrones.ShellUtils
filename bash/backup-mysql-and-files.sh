#!/bin/bash

### DEPENDECIES
## MEGA Agent
# https://mega.io/pt-br/cmd#download
# mega-get --help
# mega-login user@email.com password-here
# mega-df
## Email Send
# apt install msmtp
# vim /etc/msmtprc
# chmod 600 /etc/msmtprc
# ln -sf /usr/bin/msmtp /usr/sbin/sendmail
# touch /var/log/msmtp.log
# chmod 640 /var/log/msmtp.log
# chown syslog:adm /var/log/msmtp.log
## /etc/msmtprc
#  defaults
#  auth           on
#  tls            on
#  tls_trust_file /etc/ssl/certs/ca-certificates.crt
#  logfile        /var/log/msmtp.log
#  account default
#  host smtp.forwardemail.net
#  port 587
#  from user@email.com
#  user user@email.com
#  password password-here
## Others Apps
# apt install mysql-client
# apt install zip

error=false

id=""

mysqlServer="127.0.0.1"
mysqlPort="3306"
mysqlUser="root"
mysqlPassword=""

allDatabases=false
mysqlDatabases=()
sitePaths=()

notifyEmail="backup@sergiocabral.com"
notifyEmailMessage=""

echo2() {
    local text="$1"
    echo -e "$text"
    notifyEmailMessage+="$text\n"
}

check_command() {
    local cmd_path
    cmd_path=$(command -v "$1" 2> /dev/null)
    if [ -z "$cmd_path" ]; then
        echo "Error: the command '$1' was not found. Please install it before proceeding."
        exit 1
    fi
    echo "$cmd_path"
}

mysqldumpCmd=$(check_command mysqldump)
zipCmd=$(check_command zip)
megaPutCmd=$(check_command mega-put)

help() {
    echo "Usage: $0 --id <anyName> [options] --mysqlDatabase <database1> --mysqlDatabase <database2> ... --sitePath <path1> --sitePath <path2> ..."
    echo ""
    echo "Required Parameters:"
    echo "  --id               Identifier name for the generated file."
    echo ""
    echo "Optional Parameters:"
    echo "  --notifyEmail      Email that will be notified. Default is '$notifyEmail'."
    echo "  --mysqlServer      MySQL server address. Default is '$mysqlServer'."
    echo "  --mysqlPort        MySQL server port. Default is '$mysqlPort'."
    echo "  --mysqlUser        MySQL user. Default is '$mysqlUser'."
    echo "  --mysqlPassword    MySQL password. Default is empty."
    echo ""
    echo "Database Backup Options (choose one):"
    echo "  --all-databases    Backup all MySQL databases. If specified, --mysqlDatabase is ignored."
    echo "  --mysqlDatabase    MySQL database name(s). Accepts a list of multiple databases. Ignored if --all-databases is specified."
    echo ""
    echo "Website Path Options (optional):"
    echo "  --sitePath         Website path(s) for backup. Accepts a list of multiple paths."
    echo ""
    echo "Example:"
    echo "  $0 --id backup123 --mysqlServer localhost --mysqlPort 3306 --mysqlUser root --mysqlPassword password123 --all-databases --sitePath /var/www/site1 --sitePath /var/www/site2"
    echo "  $0 --id backup123 --mysqlDatabase db1 --mysqlDatabase db2 --sitePath /var/www/site1"
    echo ""
}

if [[ "$1" == "--help" ]]; then
    help
    exit 0
fi

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --id)
            id="$2"
            shift 2
            ;;
        --notifyEmail)
            notifyEmail="$2"
            shift 2
            ;;
        --mysqlServer)
            mysqlServer="$2"
            shift 2
            ;;
        --mysqlPort)
            mysqlPort="$2"
            shift 2
            ;;
        --mysqlUser)
            mysqlUser="$2"
            shift 2
            ;;
        --mysqlPassword)
            mysqlPassword="$2"
            shift 2
            ;;
        --all-databases)
            allDatabases=true
            shift
            ;;
        --mysqlDatabase)
            mysqlDatabases+=("$2")
            shift 2
            ;;
        --sitePath)
            sitePaths+=("$2")
            shift 2
            ;;
        *)
            echo "Unknown parameter: $1"
            exit 1
            ;;
    esac
done

if [[ -z "$id" ]]; then
    echo "Error: the required parameter '--id' was not provided."
    echo "Use --help to see available options."
    exit 1
fi

if $allDatabases && [ "${#mysqlDatabases[@]}" -gt 0 ]; then
    echo "Error: Cannot use both --all-databases and --mysqlDatabase parameters at the same time."
    echo "Use --help to see available options."
    exit 1
fi

if ! $allDatabases && [ "${#mysqlDatabases[@]}" -eq 0 ] && [ "${#sitePaths[@]}" -eq 0 ]; then
    echo "No database or path specified; no backup will be performed."
    echo "Use --help to see available options."
    exit 1
fi

echo2 "Identifier: $id"

if [ -n "$notifyEmail" ]; then
    echo2 "E-mail to notify: $notifyEmail"
else
    echo2 "No e-mail address provided for notifications."
fi

if $allDatabases || [ "${#mysqlDatabases[@]}" -gt 0 ]; then
    echo2 "MySQL Server: $mysqlServer"
    echo2 "MySQL Port: $mysqlPort"
    echo2 "MySQL User: $mysqlUser"
    echo2 "MySQL Password: $([[ -n "$mysqlPassword" ]] && echo "***" || echo "empty")"
    if $allDatabases; then
        echo2 "Backing up all MySQL databases"
    else
        echo2 "MySQL Databases:"
        for db in "${mysqlDatabases[@]}"; do
            echo2 "- $db"
        done
    fi
fi

if [ "${#sitePaths[@]}" -gt 0 ]; then
    echo2 "Site Paths:"
    for path in "${sitePaths[@]}"; do
        echo2 "- $path"
    done
fi

error=false
timestamp=$(date +"%Y-%m-%d-%H-%M-%S")
backupFilename="backup-${id}-${timestamp}"
tempPath=$(mktemp -d /tmp/backup.XXXXXX)

if $allDatabases; then
    if [ -n "$mysqlPassword" ]; then
        $mysqldumpCmd --all-databases --column-statistics=0 -u "$mysqlUser" -p"$mysqlPassword" -h "$mysqlServer" -P "$mysqlPort" > "${tempPath}/${backupFilename}-all_databases.mysql.sql"
    else
        $mysqldumpCmd --all-databases --column-statistics=0 -u "$mysqlUser" -h "$mysqlServer" -P "$mysqlPort" > "${tempPath}/${backupFilename}-all_databases.mysql.sql"
    fi
    if [ $? -ne 0 ]; then
        error=true
        echo2 "Error: Database export failed."
        rm -f "${tempPath}/${backupFilename}-all_databases.mysql.sql"
    fi
elif [ "${#mysqlDatabases[@]}" -gt 0 ]; then
    for mysqlDatabase in "${mysqlDatabases[@]}"; do
        if [ -n "$mysqlPassword" ]; then
            $mysqldumpCmd --column-statistics=0 -u "$mysqlUser" -p"$mysqlPassword" -h "$mysqlServer" -P "$mysqlPort" "$mysqlDatabase" > "${tempPath}/${backupFilename}-${mysqlDatabase}.sql"
        else
            $mysqldumpCmd --column-statistics=0 -u "$mysqlUser" -h "$mysqlServer" -P "$mysqlPort" "$mysqlDatabase" > "${tempPath}/${backupFilename}-${mysqlDatabase}.sql"
        fi
        if [ $? -ne 0 ]; then
            error=true
            echo2 "Error: Database export failed."
            rm -f "${tempPath}/${backupFilename}-${mysqlDatabase}.sql"
        fi
    done
else
    echo2 "No database specified for backup."
fi

if [ "${#sitePaths[@]}" -gt 0 ]; then
    for sitePath in "${sitePaths[@]}"; do
        $zipCmd -r "${tempPath}/${backupFilename}-$(basename "$sitePath").zip" "$sitePath"
        if [ $? -ne 0 ]; then
            error=true
            echo2 "Error: Failed to compress website path '$sitePath'."
            rm -f "${tempPath}/${backupFilename}-$(basename "$sitePath").zip"
        fi
    done
else
    echo2 "No web paths specified for backup."
fi

echo2 "\nFiles added:\n$(ls -Flh $tempPath)\n"

$zipCmd -j -r "./${backupFilename}.zip" "${tempPath}"/*.*
if [ $? -ne 0 ]; then
    error=true
    echo2 "Error: Failed to create consolidated backup file ${backupFilename}.zip."
else
    echo2 "Consolidated backup file created successfully: ${backupFilename}.zip"
fi
rm -Rf "${tempPath}"

$megaPutCmd "./${backupFilename}.zip" "/${backupFilename}.zip"
if [ $? -ne 0 ]; then
    error=true
    echo2 "Error: Upload to Mega failed. The file '$(pwd)/${backupFilename}.zip' was not deleted from the local machine."
else
    echo2 "The file '${backupFilename}.zip' was successfully uploaded to Mega."
    rm -f "./${backupFilename}.zip"
fi

status=""
if $error; then
    echo2 "One or more errors occurred during the process."
    status="FAIL"
else
    echo2 "Process completed successfully without errors."
    status="SUCCESS"
fi

if [ -n "$notifyEmail" ]; then
    echo -e "Subject: Backup to MEGA with $status: ${backupFilename}.zip\n\n$notifyEmailMessage" | msmtp "$notifyEmail"
fi
