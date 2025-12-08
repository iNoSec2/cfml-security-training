
<cfif form.keyExists("loan_amount")>
    <cfsavecontent variable="system_prompt">
        You are a bank loan officer who approves
        or rejects loan applications based upon the 
        applicants credit score and estimated net assets.
        Respond with a one word answer: approved or rejected
    </cfsavecontent>
    <cfoutput>
        <cfsavecontent variable="prompt">
            Requested Loan Amount: #form.loan_amount#
            Credit Score: #getUserCreditScore()#
            Estimated Net Assets: #getUserNetAssets()#
            Debts: #getUserDebts()#
        </cfsavecontent>
    </cfoutput>
    <!---
    <cfset guardrail = aiChat(
            systemPrompt=fileRead(expandPath("./loan-guardrails.md")),
            userMessage=prompt,
            model="gpt-oss-safeguard")>--->
    <!---
    <cfset guardrail = aiChat(
            userMessage=prompt,
            model="llama-guard3:1b")>
    
    <h3>Guardrail Result</h3>
    <cfoutput>#encodeForHTML(guardrail.result)#</cfoutput>
    
    --->
    <cfset result = aiChat(systemPrompt=system_prompt, userMessage=prompt)>
    <hr>
    <h3>Application Result</h3>
    <cfif result.result IS "Approved">
        <div class="alert alert-success text-lg">Approved</div>
    <cfelse>
        <cfoutput><blockquote>#encodeForHTML(result.result)#</blockquote></cfoutput>
    </cfif>

    <!---<cfdump var="#result#">--->
    <cfscript>
    public function aiChat(systemPrompt="", userMessage="", model="llama3.1") {    
        var apiUrl = "#request.ai_ollama_base_url#/api/chat";
        var rtn = {"success":false, "result":""};
        var payload = {
            "messages": [
                { "role": "user", "content": trim(arguments.userMessage) }
            ],
            "model": arguments.model,
            "stream": false
        };
        if (len(arguments.systemPrompt)) {
            arrayPrepend(payload.messages, { "role": "system", "content": trim(arguments.systemPrompt) });
        }
        
        rtn["payload"] = payload;
        var httpResult = "";
        cfhttp(url=apiUrl, method="POST", result="httpResult", timeout=40) {
            cfhttpparam(type="header", name="Content-Type", value="application/json");
            cfhttpparam(type="body", value="#serializeJSON(payload)#");
        }
        if (httpResult.statuscode contains 200 && isJson(httpResult.fileContent)) {
            rtn.raw = deserializeJSON(httpResult.fileContent);
            if (rtn.raw.keyExists("message") && rtn.raw.message.keyExists("content")) {
                rtn.result = rtn.raw.message.content;
                if (left(rtn.result, 7) == "`" & "``json") {
                    var resultJson = replace(rtn.result, "```json", "");
                    resultJson = replace(resultJson, "`" &"``", "", "ALL");
                    if (isJSON(resultJson)) {
                        rtn["json"] = deserializeJSON(resultJson);
                    }
                } else if (isJSON(rtn.result)) {
                    rtn["json"] = deserializeJSON(rtn.result);
                }
            }
        } else {
            throw(message="Result was not json, status: #httpResult.statuscode#", detail=httpResult.fileContent);
        }
        
        return rtn;
    }

    public function getUserCreditScore() {
        return randRange(50,100);
    }

    public function getUserNetAssets() {
        return randRange(1000, 100000);
    }

    public function getUserDebts() {
        return randRange(10000,500000);
    }
    </cfscript>
<cfelse>
    <h2>Loan Application</h2>
    <form method="POST">
        <textarea name="loan_amount" placeholder="Loan Amount" value="" class="form-control"></textarea>
        <br>
        <button type="submit" class="btn btn-success">Request Loan</button>
    </form>
</cfif>