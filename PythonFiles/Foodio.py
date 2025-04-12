
from selenium import webdriver
from selenium.webdriver.support.wait import WebDriverWait
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver import  ChromeOptions
from selenium.webdriver.common.keys import Keys



from bidi.algorithm import get_display

import time
import os
import json
import arabic_reshaper

usersData = {}

ROOT_DIR = os.path.dirname(os.path.abspath(__file__)) 
FILE_PATH = f"{ROOT_DIR}/accounts.json"

username = ""
password = ""

if os.path.exists(FILE_PATH) :
    accountInfo = open(FILE_PATH,"r")
    usersData = json.loads(accountInfo.read())
    accountInfo.close()

else :
    accountInfo = open(FILE_PATH,"w")
    accountInfo.write(json.dumps({}))
    accountInfo.close()

def convert(text):
    reshaped_text = arabic_reshaper.reshape(text)
    converted = get_display(reshaped_text)
    return converted

def account():
        global username
        global password

        accName = input(convert("اسم کاربر را وارد کنید : \n"))
        accUser = input(convert("شماره دانشجویی را وارد کنید : \n"))
        accPass = input(convert("رمز حساب کاربری را وارد کنید : \n"))
        usersData[accName] = [accUser,accPass]

        accountInfo = open(FILE_PATH,"w")
        accountInfo.write(json.dumps(usersData))
        accountInfo.close()

        username = accUser
        password = accPass


def openWeb():
    opts = ChromeOptions()
    opts.add_argument("--log-level=1")
    opts.add_argument("--window-size=700,800")
    opts.add_argument('ignore-certificate-errors')


    webPage =  webdriver.Chrome(options=opts)

    webPage.set_window_position(20,40)
    webPage.get("https://food.guilan.ac.ir/nurture/user/multi/reserve/showPanel.rose?selectedSelfDefId=4")

    print(convert("درحال آماده سازی ..."))
    versionControl(webPage)

def versionControl(webPage):
    loginAccount(webPage)

def loginAccount(webPage) :
    print(convert("درحال ورود به حساب کاربری ..."))

    WebDriverWait(webPage, 10).until(
        EC.presence_of_element_located((By.NAME, "username")) 
    )

    username_field = webPage.find_element(By.NAME, "username") 
    password_field = webPage.find_element(By.NAME, "password") 

    username_field.send_keys(username)
    password_field.send_keys(password + Keys.RETURN) 
    
    try:
        WebDriverWait(webPage, 1).until(
                EC.presence_of_element_located((By.CSS_SELECTOR, '#pageTD > table > tbody > tr:nth-child(2) > td')))
    finally :
        webPage.get("https://food.guilan.ac.ir/nurture/user/multi/reserve/showPanel.rose?selectedSelfDefId=4")
    
        getFoods(webPage)

def getFoods(webPage):
    itemNum = 0
    for item in webPage.find_elements(By.TAG_NAME,"label"):
        item_class = item.get_attribute("for")
        
        if item_class == f"userWeekReserves.selected{itemNum}" :
            foodName = "{} : {}".format(item.text.split("|")[1],itemNum)
        
            print(convert(foodName))
            itemNum += 1
    selectFoodNum(webPage)

def selectFoodNum(webPage):
    print("""
        * {} *
    """.format(convert("با استفاده از '-' شماره هارو جدا کنید")))
    userInput = input(" : {}\n".format(convert("شماره غدای مورد نظر را وارد کنید "))).split("-")
    print(convert("درحال رزرو غذا ..."))

    exist = True
    while exist :
        for i in range(len(userInput)):
            foodItem = webPage.find_elements(By.ID,f"buyFreeFoodIconSpanuserWeekReserves.selected{userInput[i]}")
            if len(foodItem) > 0 :
                exist = False
                webPage.find_element(By.ID,f"buyFreeFoodIconSpanuserWeekReserves.selected{userInput[i]}").click()
                WebDriverWait(webPage, 10).until(EC.alert_is_present())
                webPage.switch_to.alert.accept()
                time.sleep(0.2)
                webPage.find_element(By.XPATH,'//*[@id="doReservBtn"]').click()
                print(convert(" :) غذا رزرو شد "))
                webPage.quit() 
                break
        
        webPage.refresh()

print(chr(27) + "[2J")
print("""


██╗░░██╗███████╗░██████╗░█████╗░███╗░░░███╗███████╗░██████╗
██║░░██║██╔════╝██╔════╝██╔══██╗████╗░████║╚════██║██╔════╝
███████║█████╗░░╚█████╗░███████║██╔████╔██║░░███╔═╝╚█████╗░
██╔══██║██╔══╝░░░╚═══██╗██╔══██║██║╚██╔╝██║██╔══╝░░░╚═══██╗
██║░░██║███████╗██████╔╝██║░░██║██║░╚═╝░██║███████╗██████╔╝
╚═╝░░╚═╝╚══════╝╚═════╝░╚═╝░░╚═╝╚═╝░░░░░╚═╝╚══════╝╚═════╝░
                    -= Foodio v0.1 =-
""")

print(convert("""
   اضافه/آپدیت کردن حساب کاربری :1 
   رزرو غذا :2 
"""))

chooseOption = input(convert("شماره مورد نظر را وارد کنید :\n"))

while True:

    if chooseOption == "1" :
        account()
        openWeb()
        break
    elif chooseOption == "2" :
        if len(usersData) > 0 :
            for i, key in enumerate(usersData.keys()):
                print(f"{i} : {key}")
            
            accInput = input("{}".format(convert(": حساب مورد نظر را انتخاب کنید \n")))
            key, value = list(usersData.items())[int(accInput)]

            print(f"""
            {key}   : {convert("حساب کاربری انتخاب شده")}
            {value[0]}   : {convert("شماره دانشجویی")}
            {value[1]}   : {convert("رمز حساب کاربری")}
            """)

            username,password = value[0],value[1]
            openWeb()
        else:
            account()
            openWeb()
        accountInfo.close()
        break
    else :
        chooseOption = input(convert("شماره مورد نظر را به درستی وارد کنید :\n"))