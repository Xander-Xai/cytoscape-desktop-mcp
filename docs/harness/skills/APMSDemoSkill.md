## Affinity Purification - Mass Spec(AP-MS) Demo
This is series of individual prompts, each is a step to perform an action on Cytoscape desktop. 

### Instructions
Do each step one at at time in the sequence presented. Each step must result in activating an mcp tool related to Cytoscape or one of your built-in tools for file system and web retrieval to achieve the desired result and complete with success. No Cytoscape localhost CyRest HTTP calls are allowed to be used in this exercise to interact with Cytoscape as only cyctoscape mcp tools must be used. If a problem is encountered using mcp tools for a step and a success result cannot be obtained, then halt at that point and report what the issue may be. 

### Step 1
Download the AP-MS experiment data file to current working directory on local machine from this url - https://cytoscape.github.io/cytoscape-tutorials/protocols/data/ap-ms-demodata.csv. If the file is already present then skip this step.

### Step 2
load a new network view in cytoscape from the ap-ms-demodata.csv tabular file present in current dirctory and specify a custom column mapping of bait is source node, prey is target node and ap-ms score is edge attrib and rest of columns should be mapped to target node attribs. Specify a unique name of 'ap ms demo network xx' for the network to avoid duplicate collision with any pre-existing networks that may be on desktop. And remember the network suid returned as will use it in step 5 later.

### Step 3
filter the node table by selecting all rows that have HekScore < .780 and deleting those rows from node table as we want to focus on kidney cells. 

### Step 4
extract the values from name column of node table to a new temp file that is just one long comma separated string of each name.

### Step 5
submit the string of node names as a string network protein query with .999 confidence, specify a unique name of 'ap-ms demo string network xx' to avoid creating a new string network with duplicate collision on any pre-existing networks with same name on desktop. 

### Step 6
merge the new string network into the original ap ms network created from Step #2 as a union using query term to name respectively for matching nodes.

### Step 7
set the style to default on the merged network.

### Step 8
create a unique newly named style called 'demo style XX' from current style and switch to new style, XX is used for duplication buster, avoid name collision if other styles exist with same prefix.

### Step 9
set the layout to prefuse force directed with spring length of 100 and default node mass to 3.

### Step 10
change the node shape to ellipse and lock node width and height and set node size to 50.

### Step 11
set default node fill color to light grey.

### Step 12
Create a continuous mapping for the node Fill Color using the HekScore column and use a purple gradient palette.

### Step 13
set default node fill color to orange.

### Step 14
perform string functional enrichment and show the string enrichment tab in cytoscape.

### Step 15
add a filter to the string functional enrichment table to only show rows that have category value equal to the exact term of "GO Biological Process" and remove redundant terms.

### Step 16
add a split donut chart onto nodes which represents top terms from the filtered string enrichment table.

### Step 17
set passthrough mapping of node label to display name. 

### Step 18
set continuous mapping on edge width based on 'ap ms score' between 1 and 5.

### Step 19
Set default edge stroke Color to green.

### Step 20
Create a Discrete mapping for edge stroke Color on the interaction column to grey if the interaction column value is 'pp'

### Step 21
export a png image of current networkview with a new unique filename of apms-demo-<current_timestamp>.png.



