#! python

# ark_approvedSubmissionInfo.py

import sys
import synapseclient
import os.path
import pandas as pd
import synapseutils

sys.version
syn = synapseclient.login()

# MAIN
results = []
pages = list(range(50, 1500, 50))
for page in pages:
  page_token = f"50a{page}"
  response_body = "".join(["{", f"accessRequirementId: '9605913', nextPageToken: '{page_token}'", "}"])
  print(response_body)
  response = syn.restPOST(uri = "https://repo-prod.prod.sagebase.org/repo/v1/accessRequirement/9605913/approvedSubmissionInfo", body = response_body)
  results = results + response['results']
  
  if "nextPageToken" not in response.keys():
    break

# WRANGLE
data = {'Project Lead' : [], 'Institution': [], 'Datetime': []}
for DUC in results:
  data['Project Lead'].append(DUC['projectLead'])
  data['Institution'].append(DUC['institution'])
  data['Datetime'].append(DUC['modifiedOn'])

df = pd.DataFrame(data)
fid = "temp_results.csv"
df.to_csv(fid, index = False, header = ['Project Lead', 'Institution', 'Datetime'])


# END
