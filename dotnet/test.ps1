        while [ "$all_succeeded" = "False" ]; do
          for subfolder in ${TEMPLATES}; do
              versionFilePath="${subfolder}${versionFileName}"

              if [ -f "$versionFilePath" ]; then
                  subFolderName=$(basename "$subfolder")
                  if echo "${TEMPLATES_SUBDIR}" | grep -q "$subFolderName"; then
                    echo $subFolderName
                    subFolderName_pull="${subFolderName}-image-build-pr"
                    pipeline_run_names=$(kubectl get pipelinerun -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep "^$subFolderName_pull")

                    if [ -z "$pipeline_run_names" ]; then
                      echo "No PipelineRun found with prefix $subFolderName_pull"
                      exit 1
                    fi

                    sleep 20
                    all_succeeded="True"
                    echo "$pipeline_run_names" | while read -r pipelinerun; do
                      echo "Fetching status of PipelineRun: $pipelinerun"
                      pipeline_run_status=$(kubectl get pipelinerun "$pipelinerun" -o jsonpath='{.status.conditions[?(@.type=="Succeeded")].status}')

                      if [ "$pipeline_run_status" == "True" ]; then
                        echo "PipelineRun $subFolderName succeeded!"
                      elif [ "$pipeline_run_status" == "False" ]; then
                        echo "PipelineRun $subFolderName failed!"
                        all_succeeded="False"
                        break
                      else
                        echo "PipelineRun $subFolderName is still running..."
                        all_succeeded="False"
                      fi

                      echo "All succeeded is $all_succeeded"
                      if [ "$all_succeeded" = "False" ]; then
                        echo "Not all specified pipelines have succeeded. checking again in $retry_delay"
                        sleep $retry_delay
                      fi
                    done
                  fi
              else
                  echo -e "\n Version file not found in $subfolder"
              fi
          done
        done
