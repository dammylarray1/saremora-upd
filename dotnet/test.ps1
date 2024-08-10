retry_delay=120
        all_succeeded="False"
        completed_pipelines_pull=()

        while [ "$all_succeeded" = "False" ]; do
          all_succeeded="True"
          for subfolder in ${TEMPLATES}; do
              versionFilePath="${subfolder}${versionFileName}"

              if [ -f "$versionFilePath" ]; then
                  subFolderName=$(basename "$subfolder")
                  if echo "${TEMPLATES_SUBDIR}" | grep -q "$subFolderName"; then
                    echo $subFolderName
                    subFolderName_pull="${subFolderName}-image-build-pr"
                    pipeline_run_names=$(kubectl get pipelinerun -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep "^$subFolderName_pull")

                    if [ -z "$pipeline_run_names" ]; then
                      echo "The PipelineRun $subFolderName_pull has either succeeded and been deleted or can't be found"
                      continue
                    fi

                    sleep 20

                    for pipelinerun in $(echo "$pipeline_run_names"); do
                      if [[ " ${completed_pipelines_pull[@]} " =~ " ${pipelinerun} "]]; then
                        echo "Skipping already completed PipelineRun: $pipelinerun"
                        continue
                      fi

                      echo "Fetching status of PipelineRun: $pipelinerun"
                      pipeline_run_status=$(kubectl get pipelinerun "$pipelinerun" -o jsonpath='{.status.conditions[?(@.type=="Succeeded")].status}')

                      if [ "$pipeline_run_status" == "True" ]; then
                        echo "PipelineRun succeeded!"
                        kubectl delete pipelinerun "$pipelinerun"
                        echo "PipelineRun $pipelinerun has been deleted"
                        completed_pipelines_pull+=("$pipelinerun")
                      elif [ "$pipeline_run_status" == "False" ]; then
                        echo "PipelineRun failed!"
                        all_succeeded="False"
                        break
                      else
                        echo "PipelineRun is still running..."
                        all_succeeded="False"
                      fi
                    done
                  fi
              else
                  echo -e "\n Version file not found in $subfolder"
              fi
          done
          if [ "$all_succeeded" = "False" ]; then
            echo "Not all specified pipelines have succeeded. checking again in $retry_delay"
            sleep $retry_delay
          else
            echo "All pipelines have either succeeded or failed"
          fi
        done
