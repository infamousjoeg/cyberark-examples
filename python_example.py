#### CONTRIBUTED BY: JAKE DESANTIS ####

#### Dependencies ####
import http.client
import json
import ssl
import sys

#### PVWA REST API Functions ####
def start_cyberarkSession(logonPassword,pvwaHostname,authType = "CyberArk",logonUser = "Administrator"):

    #create global connection to be used in other cyberark functions; disable ssl verification
    global conn
    conn = http.client.HTTPSConnection(pvwaHostname,context=ssl._create_unverified_context())

    #define the logon URI
    logonURI="/PasswordVault/API/Auth/"+authType+"/Logon"

    #define the login payload/body
    logonPayload = json.dumps({
        "username": logonUser,
        "password": logonPassword
        })

    #define the header
    headers={
        'Content-Type':'application/json'
    }

    #issue the connection request
    try:
        conn.request("POST", logonURI, logonPayload, headers)
    except:
        print("Connection to "+pvwaHostname+logonURI+" Failed. Logon unsuccessful")
        sys.exit()

    #get the connection request response
    logonResult = conn.getresponse()

    #read the response
    authToken = logonResult.read()

    #Check if an error is returned and exit
    if "ErrorCode" in authToken.decode("utf-8"):
        print(authToken.decode("utf-8"))
        print("Exiting function")
        exit
    else:
        print("Login Successful")

    #create global loginresult variable (Header for other cyberark functions)
    global loginresult
    loginresult={
        'Authorization':authToken.decode("utf-8").strip('"'),
        'Content-Type':'application/json'
    }

def get_cyberarkSafes():
    #Define URI
    getSafesURI="/PasswordVault/API/Safes"

    try:
        #issue the connection request
        conn.request("GET",getSafesURI,"",loginresult)
    except:
        print("You're not logged in.")
        sys.exit()

    #get the connection request response
    getSafesResult = conn.getresponse()

    #read the response
    getSafes=getSafesResult.read()

    #return the result in the form of getSafes
    return getSafes

def add_cyberarkAccount(accountAddress,accountUsername,platformID,safeName,secretType="password",accountSecret="",noAutoMgmtReason="",remoteMachines=""):
    #Define URI
    addAccountURI="/PasswordVault/API/Accounts"

    #Build account name as if it were created by the PVWA; required
    accountName="Operating System-"+platformID+"-"+accountAddress+"-"+accountUsername
    
    #Define Body
    addAccountBody=json.dumps({
            "name":accountName,   
            "address":accountAddress,         
            "userName":accountUsername,          
            "platformId":platformID,            
            "safeName":safeName,   
            "secretType":secretType,
            "secret":accountSecret,
            "platformAccountProperties":{
                },
            "secretManagement":{
                "automaticManagementEnabled":"true",
                "manualManagementReason":noAutoMgmtReason,
            },
            "remoteMachineAccess":{
                "restrictAccess":"false",
                "remoteMachines":remoteMachines
            }
    })

    try:
        #issue the connection request
        conn.request("POST",addAccountURI,addAccountBody,loginresult)
    except:
        print("You're not logged in.")
        sys.exit()

    #get the connection request content
    addAccountResult = conn.getresponse()

    #read the response
    addAccount=addAccountResult.read()

    #Check if an error is returned and exit
    if "ErrorCode" in addAccount.decode("utf-8"):
        print(addAccount.decode("utf-8"))
        print("Exiting function")
        sys.exit()
    else:
        print("Account Added Successfully")

    #return the result in the form of addAccount
    return addAccount
