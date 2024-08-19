kubectl -n jobs get localqueues,clusterqueue
echo
echo "cluster-queue-A"
kubectl -n jobs get clusterqueue cluster-queue-a -o json|jq '.spec.resourceGroups[].flavors[].resources[].nominalQuota,.status.flavorsUsage[].resources[].total,.status.conditions[].message'|sed -e 's: :_:g'|xargs|awk '{print "CPU Quota: "$1"\t\tCPU in Use: "$5" \nMem Quota: "$2"\t\tMem in Use: "$7" \nGPU Quota: "$3"\t\tGPU in Use: "$8" \nDsk Quota: "$4"\t\tDsk in Use: "$6" \n\nStatus: "$NF}'
echo
echo "cluster-queue-B"
kubectl -n jobs get clusterqueue cluster-queue-b -o json|jq '.spec.resourceGroups[].flavors[].resources[].nominalQuota,.status.flavorsUsage[].resources[].total,.status.conditions[].message'|sed -e 's: :_:g'|xargs|awk '{print "CPU Quota: "$1"\t\tCPU in Use: "$5" \nMem Quota: "$2"\tMem in Use: "$7" \nGPU Quota: "$3"\t\tGPU in Use: "$8" \nDsk Quota: "$4"\tDsk in Use: "$6" \n\nStatus: "$NF}'
echo
kubectl -n jobs get jobs,workloads
echo
kubectl -n jobs top pods
echo
kubectl top nodes
echo
kubectl -n jobs get pods,workloads