from selenium import webdriver
from selenium.webdriver.support.wait import WebDriverWait
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver import ChromeOptions
from selenium.webdriver.common.keys import Keys
import time
import os
import json
import gradio as gr

# Configuration
usersData = {}
ROOT_DIR = os.path.dirname(os.path.abspath(__file__)) 
FILE_PATH = f"{ROOT_DIR}/accounts.json"
FONT = "Vazir, Tahoma, Arial"  # Persian-supported fonts

# Load or create accounts file
if os.path.exists(FILE_PATH):
    with open(FILE_PATH, "r", encoding='utf-8') as accountInfo:
        usersData = json.loads(accountInfo.read())
else:
    with open(FILE_PATH, "w", encoding='utf-8') as accountInfo:
        accountInfo.write(json.dumps({}, ensure_ascii=False))

class FoodioGradioApp:
    def __init__(self):
        self.webPage = None
        self.console_output = ""
        self.selected_account = None
        self.food_numbers = []
        
    def log(self, message):
        self.console_output += f"{message}\n"
        return self.console_output
    
    def account_gui(self, acc_name, acc_user, acc_pass):
        if not all([acc_name, acc_user, acc_pass]):
            return self.log("لطفا تمام فیلدها را پر کنید"), None
            
        usersData[acc_name] = [acc_user, acc_pass]
        
        with open(FILE_PATH, "w", encoding='utf-8') as accountInfo:
            json.dump(usersData, accountInfo, ensure_ascii=False)
            
        global username, password
        username = acc_user
        password = acc_pass
        
        account_list = list(usersData.keys())
        return self.log(f"حساب کاربری {acc_name} ذخیره شد"), gr.Dropdown(choices=account_list)
    
    def select_account(self, account_name):
        if not account_name:
            return self.log("لطفا یک حساب را انتخاب کنید"), None, None
        
        global username, password
        username, password = usersData[account_name]
        self.selected_account = account_name
        
        return self.log(f"حساب کاربری {account_name} انتخاب شد"), username, password
    
    def open_web(self):
        if not self.selected_account:
            return self.log("لطفا ابتدا یک حساب انتخاب کنید"), None
        
        self.log("درحال آماده سازی مرورگر...")
        
        opts = ChromeOptions()
        opts.add_argument("--log-level=1")
        opts.add_argument("--window-size=700,800")
        opts.add_argument('ignore-certificate-errors')

        self.webPage = webdriver.Chrome(options=opts)
        self.webPage.set_window_position(20, 40)
        self.webPage.get("https://food.guilan.ac.ir/nurture/user/multi/reserve/showPanel.rose?selectedSelfDefId=4")

        self.log("درحال ورود به حساب کاربری...")
        return self.login_account()
    
    def login_account(self):
        try:
            WebDriverWait(self.webPage, 10).until(
                EC.presence_of_element_located((By.NAME, "username")) 
            )

            username_field = self.webPage.find_element(By.NAME, "username") 
            password_field = self.webPage.find_element(By.NAME, "password") 

            username_field.send_keys(username)
            password_field.send_keys(password + Keys.RETURN) 
            
            self.webPage.get("https://food.guilan.ac.ir/nurture/user/multi/reserve/showPanel.rose?selectedSelfDefId=4")
            return self.get_foods()
            
        except Exception as e:
            return self.log(f"خطا در ورود به سیستم: {str(e)}"), None
    
    def get_foods(self):
        self.log("درحال دریافت لیست غذاها...")
        
        food_list = []
        itemNum = 0
        for item in self.webPage.find_elements(By.TAG_NAME, "label"):
            item_class = item.get_attribute("for")
            
            if item_class == f"userWeekReserves.selected{itemNum}":
                food_text = item.text.split('|')[1].strip()
                food_list.append(f"{food_text} : {itemNum}")
                itemNum += 1
                
        return self.log("لیست غذاها دریافت شد"), gr.CheckboxGroup(choices=food_list)
    
    def reserve_foods(self, selected_foods):
        if not selected_foods:
            return self.log("لطفا حداقل یک غذا را انتخاب کنید")
            
        food_numbers = [food.split(":")[-1].strip() for food in selected_foods]
        self.log(f"غذاهای انتخاب شده: {', '.join(food_numbers)}")
        
        try:
            exist = True
            while exist:
                for food_num in food_numbers:
                    food_item = self.webPage.find_elements(By.ID, f"buyFreeFoodIconSpanuserWeekReserves.selected{food_num}")
                    if len(food_item) > 0:
                        exist = False
                        self.webPage.find_element(By.ID, f"buyFreeFoodIconSpanuserWeekReserves.selected{food_num}").click()
                        WebDriverWait(self.webPage, 10).until(EC.alert_is_present())
                        self.webPage.switch_to.alert.accept()
                        time.sleep(0.2)
                        self.webPage.find_element(By.XPATH, '//*[@id="doReservBtn"]').click()
                        self.log("غذا با موفقیت رزرو شد")
                        break
                
                self.webPage.refresh()
                
        except Exception as e:
            self.log(f"خطا در رزرو غذا: {str(e)}")
            
        finally:
            if self.webPage:
                self.webPage.quit()
                self.webPage = None
                
        return self.console_output

def create_gradio_interface():
    app = FoodioGradioApp()
    
    css = f"""
    .gradio-container {{
        font-family: {FONT};
        direction: rtl;
        text-align: right;
    }}
    .rtl-text input, .rtl-text textarea {{
        direction: rtl;
        text-align: right;
    }}
    """
    
    with gr.Blocks(title="فودیو - سامانه رزرو غذا", css=css) as demo:
        gr.Markdown("""
        <div style="text-align: center; font-family: Vazir; direction: rtl;">
        <h1>سامانه رزرو غذا دانشگاه گیلان</h1>
        <h3>نسخه 0.1</h3>
        </div>
        """)
        
        with gr.Tabs():
            with gr.TabItem("مدیریت حساب کاربری"):
                with gr.Row():
                    with gr.Column():
                        acc_name = gr.Textbox(label="اسم کاربر", elem_classes="rtl-text")
                        acc_user = gr.Textbox(label="شماره دانشجویی", elem_classes="rtl-text")
                        acc_pass = gr.Textbox(label="رمز حساب کاربری", type="password", elem_classes="rtl-text")
                        save_btn = gr.Button("ذخیره حساب")
                        
                        account_dropdown = gr.Dropdown(
                            label="حساب های موجود",
                            choices=list(usersData.keys()),
                            interactive=True
                        )
                        select_acc_btn = gr.Button("انتخاب حساب")
                        
                    with gr.Column():
                        username_display = gr.Textbox(label="نام کاربری", interactive=False, elem_classes="rtl-text")
                        password_display = gr.Textbox(label="رمز عبور", interactive=False, elem_classes="rtl-text")
                        
            with gr.TabItem("رزرو غذا"):
                with gr.Row():
                    with gr.Column():
                        open_web_btn = gr.Button("اتصال به سیستم غذا")
                        food_checkboxes = gr.CheckboxGroup(
                            label="غذاهای موجود",
                            interactive=True
                        )
                        reserve_btn = gr.Button("رزرو غذاهای انتخاب شده")
                        
                    with gr.Column():
                        console = gr.Textbox(
                            label="وضعیت سیستم",
                            interactive=False,
                            lines=20,
                            max_lines=20,
                            elem_classes="rtl-text"
                        )
        
        # Account management
        save_btn.click(
            app.account_gui,
            inputs=[acc_name, acc_user, acc_pass],
            outputs=[console, account_dropdown]
        )
        
        select_acc_btn.click(
            app.select_account,
            inputs=[account_dropdown],
            outputs=[console, username_display, password_display]
        )
        
        # Food reservation
        open_web_btn.click(
            app.open_web,
            outputs=[console, food_checkboxes]
        )
        
        reserve_btn.click(
            app.reserve_foods,
            inputs=[food_checkboxes],
            outputs=[console]
        )
    
    return demo

if __name__ == "__main__":
    demo = create_gradio_interface()
    demo.launch(share=True)