## This is a script to call circRNA using CIRCexplorer2 and CLEAR from STAR mapped bam files
## Inputs:
## 		sample 	- samplename

version 1.0

workflow circ2_clear
{
    input {
	# input files
	File Chimeric_junction
	File bam
	File bambai
	File hg38genepred
	File hg38fasta
	File hg38fastaindex
	String sample
	Int CLEAR_vm_disk_size_gb
	String CLEAR_vm_memory
	Int CLEAR_vm_cpu_num
	
    }
    # identify circRNA by circExplorer2
    call circ2
    {
    	input:
		Chimeric_junction=Chimeric_junction,
		sample=sample,
		hg38genepred=hg38genepred,
		hg38fasta=hg38fasta,
		hg38fastaindex=hg38fastaindex
		
    }
    
    call circ3
    {
    	input:
			sample=sample,
			bam=bam,
			bambai=bambai,
			known_txt=circ2.known_txt,
			hg38genepred=hg38genepred,
			CLEAR_vm_disk_size_gb=CLEAR_vm_disk_size_gb,
			CLEAR_vm_memory=CLEAR_vm_memory,
			CLEAR_vm_cpu_num=CLEAR_vm_cpu_num
			
	    
    }
    output {
		File known_txt = "${sample}_circularRNA_known.txt"
		File circ2_log = "${sample}_CIRCexplorer2_annotate.log"
		File out = "${sample}_circRNA_quant.txt"
		File clear_log = "${sample}_circRNA_quant.log"
    }

}

task circ2
{
    input {
	String sample
	File Chimeric_junction
	File hg38genepred
	File hg38fasta
	File hg38fastaindex
    }
    
    command
    {
		CIRCexplorer2 parse -b ${sample}.back_spliced_junction.bed -t STAR ${Chimeric_junction} > ${sample}_parse.log
		CIRCexplorer2 annotate -r ${hg38genepred} \
		-g ${hg38fasta} \
		-b ${sample}.back_spliced_junction.bed \
		-o ${sample}_circularRNA_known.txt > ${sample}_CIRCexplorer2_annotate.log
    }
    
    output
    {
		File known_txt = "${sample}_circularRNA_known.txt"
		File circ2_log = "${sample}_CIRCexplorer2_annotate.log"
    }

    runtime 
    {
		docker: "bwhbioinformaticshub/circexplorer2"
		memory: "60G"
		cpu: "4"
		disks: "local-disk 200 HDD"
  	}
}

task circ3
{
    input {
	String sample
	File bam
	File bambai
	File known_txt
	File hg38genepred
	Int CLEAR_vm_disk_size_gb
	String CLEAR_vm_memory
	Int CLEAR_vm_cpu_num
    }
    
    command
    {
		circ_quant -c ${known_txt} \
		-b ${bam} \
		-r ${hg38genepred} \
		-o ${sample}_circRNA_quant.txt > ${sample}_circRNA_quant.log
	}

    output
    {
        File out = "${sample}_circRNA_quant.txt"
        File circ2_log = "${sample}_circRNA_quant.log"
    }

    runtime 
    {
        docker: "nciccbr/ccbr_clear"
        memory: CLEAR_vm_memory
        cpu: CLEAR_vm_cpu_num
        disks: "local-disk " + CLEAR_vm_disk_size_gb + " HDD"
  	}
}
