# Custom Agents & Workflows Guide

This guide shows how to integrate your custom agents and workflows with the ChatKit application.

## Table of Contents

1. [Agent Builder Integration](#agent-builder-integration)
2. [Custom Tools](#custom-tools)
3. [Workflow Integration](#workflow-integration)
4. [Example Implementations](#example-implementations)
5. [Testing & Debugging](#testing--debugging)

## Agent Builder Integration

### Using OpenAI Agent Builder Workflows

Agent Builder allows you to create multi-agent workflows visually. Follow the [AgentKit Walkthrough](https://cookbook.openai.com/examples/agentkit/agentkit_walkthrough) to build your workflow.

#### 1. Create Your Workflow

1. Go to [OpenAI Agent Builder](https://platform.openai.com/agent-builder)
2. Design your multi-agent workflow
3. Test in Preview mode
4. Publish and get the workflow ID

#### 2. Configure Backend

Update `backend/app/chat.py`:

```python
import os
from openai import AsyncOpenAI
from chatkit.server import ChatKitServer

client = AsyncOpenAI(api_key=os.getenv("OPENAI_API_KEY"))

# Your workflow ID from Agent Builder
WORKFLOW_ID = os.getenv("CHATKIT_WORKFLOW_ID", "your-workflow-id")

class WorkflowChatKitServer(ChatKitServer):
    async def process_message(self, message: str, context: dict):
        # Use workflow as model
        response = await client.chat.completions.create(
            model=WORKFLOW_ID,
            messages=[
                {"role": "system", "content": "You are a helpful assistant."},
                {"role": "user", "content": message}
            ],
            stream=True
        )
        
        async for chunk in response:
            if chunk.choices[0].delta.content:
                yield chunk.choices[0].delta.content
```

#### 3. Deploy with Workflow ID

```bash
# Update .env.deploy
CHATKIT_WORKFLOW_ID=your-workflow-id-here

# Redeploy
./deploy/deploy-backend.sh
```

## Custom Tools

### Creating a Custom Tool

Tools extend the agent's capabilities. Here's how to create one:

```python
# backend/app/tools/my_tool.py
from chatkit.server import Tool
from typing import Dict, Any

class MyCustomTool(Tool):
    """Description of what this tool does."""
    
    name = "my_custom_tool"
    description = "A clear description for the LLM to understand when to use this tool"
    
    parameters = {
        "type": "object",
        "properties": {
            "param1": {
                "type": "string",
                "description": "Description of param1"
            },
            "param2": {
                "type": "number",
                "description": "Description of param2"
            }
        },
        "required": ["param1"]
    }
    
    async def execute(self, param1: str, param2: float = 0.0) -> Dict[str, Any]:
        """Execute the tool logic."""
        try:
            # Your tool implementation
            result = self._process(param1, param2)
            
            return {
                "success": True,
                "result": result
            }
        except Exception as e:
            return {
                "success": False,
                "error": str(e)
            }
    
    def _process(self, param1: str, param2: float) -> Any:
        """Your business logic here."""
        return f"Processed {param1} with {param2}"
```

### Registering Tools

Update `backend/app/chat.py`:

```python
from .tools.my_tool import MyCustomTool
from .weather import GetWeatherTool
from .facts import RecordFactTool

# Register all tools
tools = [
    RecordFactTool(),
    GetWeatherTool(),
    MyCustomTool(),  # Your custom tool
]

def create_chatkit_server():
    return FactAssistantServer(tools=tools)
```

### Tool with Widget Response

Create interactive widgets:

```python
from chatkit.server import Tool, Widget

class InteractiveTool(Tool):
    name = "interactive_tool"
    description = "Tool that returns an interactive widget"
    
    async def execute(self, **kwargs) -> Widget:
        return Widget(
            type="confirmation",
            title="Confirm Action",
            message="Do you want to proceed?",
            actions=[
                {
                    "label": "Confirm",
                    "action": "confirm",
                    "style": "primary"
                },
                {
                    "label": "Cancel",
                    "action": "cancel",
                    "style": "secondary"
                }
            ]
        )
```

## Workflow Integration

### Integrating External Workflows

If you have existing workflows or agents:

#### 1. API-Based Integration

```python
# backend/app/workflows/external_workflow.py
import httpx
from typing import Dict, Any

class ExternalWorkflow:
    def __init__(self, api_url: str, api_key: str):
        self.api_url = api_url
        self.api_key = api_key
    
    async def execute(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """Call external workflow API."""
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{self.api_url}/execute",
                json=input_data,
                headers={
                    "Authorization": f"Bearer {self.api_key}",
                    "Content-Type": "application/json"
                },
                timeout=30.0
            )
            response.raise_for_status()
            return response.json()
```

#### 2. Wrap as ChatKit Tool

```python
# backend/app/tools/workflow_tool.py
from chatkit.server import Tool
from ..workflows.external_workflow import ExternalWorkflow
import os

class WorkflowTool(Tool):
    name = "execute_workflow"
    description = "Execute external workflow"
    
    def __init__(self):
        super().__init__()
        self.workflow = ExternalWorkflow(
            api_url=os.getenv("WORKFLOW_API_URL"),
            api_key=os.getenv("WORKFLOW_API_KEY")
        )
    
    async def execute(self, **kwargs):
        result = await self.workflow.execute(kwargs)
        return result
```

### Multi-Step Workflows

Implement complex workflows with multiple steps:

```python
# backend/app/workflows/multi_step.py
from typing import List, Dict, Any
from openai import AsyncOpenAI

class MultiStepWorkflow:
    def __init__(self):
        self.client = AsyncOpenAI()
        self.steps = []
    
    async def add_step(self, step_name: str, agent_config: Dict[str, Any]):
        """Add a step to the workflow."""
        self.steps.append({
            "name": step_name,
            "config": agent_config
        })
    
    async def execute(self, initial_input: str) -> List[Dict[str, Any]]:
        """Execute all steps in sequence."""
        results = []
        current_input = initial_input
        
        for step in self.steps:
            result = await self._execute_step(step, current_input)
            results.append({
                "step": step["name"],
                "result": result
            })
            # Use output as input for next step
            current_input = result.get("output", current_input)
        
        return results
    
    async def _execute_step(self, step: Dict, input_data: str) -> Dict[str, Any]:
        """Execute a single workflow step."""
        response = await self.client.chat.completions.create(
            model=step["config"].get("model", "gpt-4"),
            messages=[
                {"role": "system", "content": step["config"].get("system_prompt", "")},
                {"role": "user", "content": input_data}
            ]
        )
        
        return {
            "output": response.choices[0].message.content,
            "model": step["config"]["model"]
        }
```

## Example Implementations

### Example 1: Email Finder Tool

```python
# backend/app/tools/email_finder.py
from chatkit.server import Tool
import httpx
import os

class EmailFinderTool(Tool):
    """Find email addresses for contacts at companies."""
    
    name = "find_email"
    description = "Find email addresses for a person at a company using their name and company domain"
    
    parameters = {
        "type": "object",
        "properties": {
            "first_name": {
                "type": "string",
                "description": "First name of the person"
            },
            "last_name": {
                "type": "string",
                "description": "Last name of the person"
            },
            "company_domain": {
                "type": "string",
                "description": "Company domain (e.g., example.com)"
            }
        },
        "required": ["first_name", "last_name", "company_domain"]
    }
    
    async def execute(self, first_name: str, last_name: str, company_domain: str):
        """Find email address."""
        api_key = os.getenv("EMAIL_FINDER_API_KEY")
        
        if not api_key:
            return {
                "success": False,
                "error": "Email finder API key not configured"
            }
        
        async with httpx.AsyncClient() as client:
            try:
                response = await client.post(
                    "https://api.hunter.io/v2/email-finder",
                    params={
                        "domain": company_domain,
                        "first_name": first_name,
                        "last_name": last_name,
                        "api_key": api_key
                    },
                    timeout=10.0
                )
                
                if response.status_code == 200:
                    data = response.json()
                    return {
                        "success": True,
                        "email": data.get("data", {}).get("email"),
                        "confidence": data.get("data", {}).get("score")
                    }
                else:
                    return {
                        "success": False,
                        "error": f"API returned status {response.status_code}"
                    }
            except Exception as e:
                return {
                    "success": False,
                    "error": str(e)
                }
```

### Example 2: Database Query Tool

```python
# backend/app/tools/database_query.py
from chatkit.server import Tool
from google.cloud import bigquery
import os

class DatabaseQueryTool(Tool):
    """Query BigQuery database."""
    
    name = "query_database"
    description = "Query the database to retrieve information"
    
    parameters = {
        "type": "object",
        "properties": {
            "query": {
                "type": "string",
                "description": "SQL query to execute"
            }
        },
        "required": ["query"]
    }
    
    def __init__(self):
        super().__init__()
        self.client = bigquery.Client(project=os.getenv("GCP_PROJECT_ID"))
    
    async def execute(self, query: str):
        """Execute database query."""
        try:
            # Validate query (prevent destructive operations)
            if any(keyword in query.upper() for keyword in ["DROP", "DELETE", "UPDATE", "INSERT"]):
                return {
                    "success": False,
                    "error": "Only SELECT queries are allowed"
                }
            
            # Execute query
            query_job = self.client.query(query)
            results = query_job.result()
            
            # Convert to list of dicts
            rows = [dict(row) for row in results]
            
            return {
                "success": True,
                "rows": rows,
                "row_count": len(rows)
            }
        except Exception as e:
            return {
                "success": False,
                "error": str(e)
            }
```

### Example 3: Lead Generation Workflow

```python
# backend/app/workflows/lead_generation.py
from typing import Dict, Any
from openai import AsyncOpenAI
import httpx

class LeadGenerationWorkflow:
    """Multi-step lead generation workflow."""
    
    def __init__(self):
        self.client = AsyncOpenAI()
    
    async def execute(self, company_name: str, industry: str) -> Dict[str, Any]:
        """Execute lead generation workflow."""
        
        # Step 1: Research company
        company_info = await self._research_company(company_name)
        
        # Step 2: Find decision makers
        contacts = await self._find_contacts(company_name, company_info)
        
        # Step 3: Generate personalized outreach
        outreach = await self._generate_outreach(company_info, contacts)
        
        return {
            "company": company_info,
            "contacts": contacts,
            "outreach": outreach
        }
    
    async def _research_company(self, company_name: str) -> Dict[str, Any]:
        """Research company information."""
        response = await self.client.chat.completions.create(
            model="gpt-4",
            messages=[
                {
                    "role": "system",
                    "content": "You are a research assistant. Provide company information."
                },
                {
                    "role": "user",
                    "content": f"Research {company_name} and provide key information."
                }
            ]
        )
        
        return {
            "name": company_name,
            "info": response.choices[0].message.content
        }
    
    async def _find_contacts(self, company_name: str, company_info: Dict) -> list:
        """Find decision makers at the company."""
        # Integration with your contact finding service
        async with httpx.AsyncClient() as client:
            response = await client.post(
                "https://your-contact-api.com/find",
                json={"company": company_name}
            )
            return response.json().get("contacts", [])
    
    async def _generate_outreach(self, company_info: Dict, contacts: list) -> str:
        """Generate personalized outreach message."""
        response = await self.client.chat.completions.create(
            model="gpt-4",
            messages=[
                {
                    "role": "system",
                    "content": "You are a sales expert. Write personalized outreach."
                },
                {
                    "role": "user",
                    "content": f"Write outreach for {company_info['name']} targeting {contacts[0]['name']}"
                }
            ]
        )
        
        return response.choices[0].message.content
```

## Testing & Debugging

### Local Testing

```python
# backend/tests/test_custom_tool.py
import pytest
from app.tools.my_tool import MyCustomTool

@pytest.mark.asyncio
async def test_my_custom_tool():
    tool = MyCustomTool()
    result = await tool.execute(param1="test", param2=1.0)
    
    assert result["success"] is True
    assert "result" in result
```

### Testing with ChatKit

```python
# backend/tests/test_chatkit_integration.py
import pytest
from app.chat import create_chatkit_server

@pytest.mark.asyncio
async def test_chatkit_server():
    server = create_chatkit_server()
    
    # Test message processing
    response = await server.process_message(
        "Test message",
        context={}
    )
    
    assert response is not None
```

### Debugging Tips

1. **Enable Debug Logging**
   ```python
   import logging
   logging.basicConfig(level=logging.DEBUG)
   ```

2. **Test Tools Individually**
   ```bash
   # Run single tool test
   python -m pytest backend/tests/test_my_tool.py -v
   ```

3. **Use Local Docker Testing**
   ```bash
   ./deploy/local-test.sh
   ```

4. **Check Cloud Run Logs**
   ```bash
   gcloud run services logs read chatkit-backend --region=us-central1
   ```

5. **Monitor API Calls**
   ```python
   # Add request/response logging
   @app.middleware("http")
   async def log_requests(request, call_next):
       logger.info(f"Request: {request.method} {request.url}")
       response = await call_next(request)
       logger.info(f"Response: {response.status_code}")
       return response
   ```

## Best Practices

1. **Error Handling**: Always handle errors gracefully
2. **Validation**: Validate inputs before processing
3. **Timeouts**: Set appropriate timeouts for external calls
4. **Logging**: Log important events and errors
5. **Testing**: Write tests for all custom tools
6. **Documentation**: Document tool parameters clearly
7. **Security**: Never expose sensitive data in responses
8. **Rate Limiting**: Implement rate limiting for expensive operations

## Next Steps

- Review [CLOUD_RUN_DEPLOYMENT.md](CLOUD_RUN_DEPLOYMENT.md) for deployment
- Check [AgentKit Walkthrough](https://cookbook.openai.com/examples/agentkit/agentkit_walkthrough) for workflow examples
- Explore [OpenAI Agents SDK](https://github.com/openai/openai-agents-python) documentation
