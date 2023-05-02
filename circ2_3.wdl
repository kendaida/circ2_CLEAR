## This is a script to call circRNA using CIRCexplorer2 and CLEAR from STAR mapped bam files
## Inputs:
## 		sample 	- samplename

workflow circ2_clear
{
	# input files
	File Chimeric_junction
	File bam
	String sample

    # identidy circRNA by circExplorer2
    call circ2
    {
    	input:
		Chimeric_junction=Chimeric_junction,
		sample=sample
    }
    
    call circ3
    {
    	input:
          	sample=sample,
            bam=bam
    }
}

task circ2
{
	String sample
	File Chimeric_junction
    
    command
    {
        CIRCexplorer2 parse -b {sample}.back_spliced_junction.bed -t STAR {Chimeric_junction} > {sample}_parse.log
        CIRCexplorer2 annotate -r hg38.txt \
        -g Homo_sapiens_assembly38_noALT_noHLA_noDecoy.fasta \
        -b {sample}.back_spliced_junction.bed} \
        -o {sample}_circularRNA_known.txt > {sample}_CIRCexplorer2_annotate.log

	}
    
    output
    {
        File known_txt = "{sample}_circularRNA_known.txt"
        File circ2_log = "{sample}_CIRCexplorer2_annotate.log"
    }

    runtime 
    {
        docker: "bwhbioinformaticshub/circexplorer2"
        memory: "60G"
        cpu: "4"
        disk: "local-disk 2000 HDD"
  	}
}

task circ3
{
	String sample
	File bam
    
    command
    {
        circ_quant -c {sample}_circularRNA_known.txt \
        -b {bam} \
        -r hg38.txt \
        -o {sample}_circRNA_quant.txt > {sample}_circRNA_quant.log
	}

    output
    {
        File out = "{sample}_circRNA_quant.txt"
        File circ2_log = "{sample}_circRNA_quant.log"
    }

    runtime 
    {
        docker: "nciccbr/ccbr_clear"
        memory: "60G"
        cpu: "4"
        disk: "local-disk 2000 HDD"
  	}
}
