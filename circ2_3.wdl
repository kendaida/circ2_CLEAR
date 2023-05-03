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
	File hg38genepred
	String sample
    }
    # identify circRNA by circExplorer2
    call circ2
    {
    	input:
		Chimeric_junction=Chimeric_junction,
		sample=sample
		hg38genepred=hg38genepred
    }
    
    call circ3
    {
    	input:
          	sample=sample,
            bam=bam,
	    known_txt=circ2.known_txt
	    
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
    }
    command
    {
        CIRCexplorer2 parse -b ${sample}.back_spliced_junction.bed -t STAR ${Chimeric_junction} > ${sample}_parse.log
        CIRCexplorer2 annotate -r ${hg38genepred} \
        -g Homo_sapiens_assembly38_noALT_noHLA_noDecoy.fasta \
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
        disk: "local-disk 2000 HDD"
  	}
}

task circ3
{
    input {
        String sample
	File bam
	File known_txt
    }
    command
    {
        circ_quant -c ${known_txt} \
        -b ${bam} \
        -r hg38.txt \
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
        memory: "60G"
        cpu: "4"
        disk: "local-disk 2000 HDD"
  	}
}
