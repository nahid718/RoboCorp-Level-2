*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipt and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive


*** Variables ***
${folderpath}=      E:\\my-first-robot\\output\\Report


*** Tasks ***
Orders robots from RobotSpareBin Industries Inc
    Open the robot website
    Fill the form using data from the CSV file
    Zip the report file
    [Teardown]    Close Browser


*** Keywords ***
Open the robot website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    Maximize Browser Window
    Click Button    css:#root > div > div.modal > div > div > div > div > div > button.btn.btn-dark

Fill the form using data from the CSV file
    ${orders} =    Read table from CSV    orders.csv    header=True
    FOR    ${order}    IN    @{orders}
        Fill robot requirement    ${order}
    END

Close Browser
    Close Browser

Fill robot requirement
    [Arguments]    ${order}
    Select From List By Value    head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${order}[Legs]
    Input Text    address    ${order}[Address]
    Wait Until Keyword Succeeds    10x    1 sec    Click Button    Preview
    Set Selenium Implicit Wait    1 seconds
    Wait Until Keyword Succeeds    10x    1 sec    Click Button    Order
    Set Selenium Implicit Wait    1 seconds

    TRY
        ${recipt_result_html} =    Get Element Attribute    id:receipt    outerHTML
    EXCEPT
        Log    Server Error
        Set Selenium Implicit Wait    1 seconds
        Click Button    Order
        TRY
            ${recipt_result_html} =    Get Element Attribute    id:receipt    outerHTML
        EXCEPT
            Set Selenium Implicit Wait    1 seconds
            Click Button    Order
            ${recipt_result_html} =    Get Element Attribute    id:receipt    outerHTML
        END
        ${recipt_result_html} =    Get Element Attribute    id:receipt    outerHTML
    END

    Html To Pdf    ${recipt_result_html}    ${OUTPUT_DIR}${/}Receipt${/}${order}[Order number].pdf
    ${screenshot} =    Screenshot    css:#robot-preview-image    ${OUTPUT_DIR}${/}Robot${/}${order}[Order number].PNG
    ${pd} =    Open Pdf    ${OUTPUT_DIR}${/}Receipt${/}${order}[Order number].pdf
    ${files} =    Create List    ${OUTPUT_DIR}${/}Robot${/}${order}[Order number].PNG
    ...    ${OUTPUT_DIR}${/}Receipt${/}${order}[Order number].pdf
    Add Files To Pdf    ${files}    ${OUTPUT_DIR}${/}Report${/}${order}[Order number].pdf
    Close Pdf    ${pd}
    Set Selenium Implicit Wait    1 seconds
    Wait Until Keyword Succeeds    10x    1 sec    Click Button    Order another robot
    Set Selenium Implicit Wait    1 seconds
    Click Button    css:#root > div > div.modal > div > div > div > div > div > button.btn.btn-dark

Zip the report file
    Archive Folder With Zip    ${folderpath}    Report.zip
