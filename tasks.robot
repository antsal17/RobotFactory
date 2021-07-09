*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library  RPA.PDF
Library  RPA.Robocloud.Secrets
Library  RPA.HTTP
Library  OperatingSystem
Library  RPA.Excel.Files
Library  RPA.Archive
Library  RPA.Dialogs
Library  CSVLib
Library  RPA.Browser.Selenium

*** Keywords ***
Open the Browser and accept conditions
    Open Available Browser     https://robotsparebinindustries.com/#/robot-order

*** Keywords ***
Collect Site to robots
    Add text input    search    label=Search query
    ${response}=    Run dialog
    [Return]    ${response.search}

*** Keywords ***
Download the CSV file
    [Arguments]  ${site}
    Download  ${site}  ${CURDIR}${/}Data  overwrite=true

*** Keywords ***
Creat Robots
    [Arguments]  ${row}
    Click Button When Visible  //button[@class="btn btn-dark"]
    Select From List By Value  id:head  ${row}[1]
    Select Radio Button  body  ${row}[2]
    Input Text    //input[@class="form-control"]    ${row}[3]
    Input Text    id:address  ${row}[4]
    Click Button When Visible  id:preview
    Click Button When Visible  id:order
    #Wait Until Element Is Visible    id:order-completion
    ${alert_modal}=  Is Element Enabled  //div[@class="alert alert-danger"]
    Run Keyword If  "${alert_modal}" == "True"  Verify if order is complete
    sleep  2
    #${alert_modal}=  Is Element Enabled  //div[@class="alert alert-danger"]
     
    #IF    "${alert_modal}" == "True"
      #Log    ${alert_modal}  
      #Click Button When Visible  id:order  
    #END

*** Keywords ***
Verify if order is complete
    Click Button When Visible  id:order
    #Wait Until Element Is Visible    id:order-completion
    ${alert_modal}=  Is Element Enabled  //div[@class="alert alert-danger"]
    Run Keyword If  "${alert_modal}" == "True"  Verify if order is complete

*** Keywords ***
Save robot in PDF file
      [Arguments]  ${row}
      #Wait Until Element Is Visible    id:order-completion
      ${order_receipt}=  Get Element Attribute    id:receipt    outerHTML
      Wait Until Keyword Succeeds  3x  0.5s   Screenshot    id:robot-preview-image    ${CURDIR}${/}Orders${/}Images${/}robot_order${row}[0].png
      ${order_image}=  Catenate   SEPARATOR=   <div><img src="  ${CURDIR}${/}Orders${/}Images${/}robot_order${row}[0].png  " alt="imagem"/></div>
      ${order_final}=  Catenate  ${order_receipt}  ${order_image}
      HTML to PDF    ${order_final}  ${CURDIR}${/}Orders${/}OrderPDF${row}[0].pdf      

*** Keywords ***
Loop workbook
    ${list}=		Read Csv As List		${CURDIR}${/}Data${/}orders.csv
    [Return]  ${list}



*** Keywords ***
Create zip archive
    Archive Folder With ZIP   ${CURDIR}${/}Orders  Orders.zip   recursive=True  include=*.pdf  exclude=*.png




*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${site}=  Collect Site to robots
    ${site_credentias}=    Get Secret    credentials
    log  ${site}
    Download the CSV file  ${site_credentias}[url]
    Open the Browser and accept conditions
    ##Download the CSV file
    ${rows}=  Loop workbook
    FOR    ${row}   IN    @{rows}
    IF    "${row}[1]" != "Head"
    Creat Robots  ${row}
    Save robot in PDF file  ${row}
    Click Button When Visible  id:order-another
    END       
    END
    Create zip archive
    Close Browser


