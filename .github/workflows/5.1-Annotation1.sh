# Annotation of Thalassiosirales transcriptomes using trinotate pipeline
# Requirements:
# Trinity v2.1.1, Trinotate v3.2.1,  Diamond v0.9.9.110, hmmscan v3.1b, tmHMM v2.0c & SignalP v5.0
# Databases:
# NCBI RefSeq nr Release 200, Uniprot/Swiss-Prot  2020_1,  Pfam 33.1

# generate the trans_map file from the assembly
for file in ../*-Trinity.fasta
do
perl /usr/local/bin/trinityrnaseq/util/support_scripts/get_Trinity_gene_to_trans_map.pl ${file} > $${file%%}_gene_trans_map
done

# Convert .fasta swiss-prot database in diamond compatible format
diamond makedb --in ../DATABASES/uniprot_sprot.fasta -d swiss-prot

# .fasta files generated by trinity assembly must be in working directory
# Diamond Blastx

for file in ../*-Trinity.fasta
do
diamond blastx -d swiss-prot -q ${file} -o ${file%%}-blastx_swiss.outfmt6 -p 8 --sensitive -f 6 -k 1 -e 0.00001
done


# .pep files generated by transdecoder.Predict must be in working directory
# Diamond Blastp
for file in *.pep
do
diamond blastp -d swiss-prot -q ${file} -o ${file%%}-blastp_swiss.outfmt6 -p 8 --sensitive -f 6 -k 1 -e 0.00001
done

# hmmscan against pfam

for file in *.pep
do
hmmscan --cpu 8 --domtblout ${file%%}-PFAM.out ../DATABASES/Pfam-A.hmm ${file}
done


# signalP annotation

for file in *.pep
do
signalp -f short -n ${file%%}-signalp.out ${file}
done



# tmhmm annotation

for file in *.pep
do
tmhmm --short < ${file}  > ${file%%}-tmhmm.out
done

# assembly file (Trinity.fasta) and Peptide file (.pep) on working directory together with all annotations
# Initializing the database and load results (results of previous annotations shoul be in working directory)

for file in *-Trinity.fasta
do
transmap=${file/.fasta/.fasta_gene_trans_map}
pep=${file/.fasta/.fasta.transdecoder.pep}
blasp=${file/.fasta/.fasta.transdecoder.pep-blastp_swiss.outfmt6}
blasp=${file/.fasta/.fasta.transdecoder.pep-blastp_swiss.outfmt6}
hmmscan=${file/.fasta/.fasta.transdecoder.pep-PFAM.out}
signalp=${file/.fasta/.fasta.transdecoder.pep-signalp.out}
tmhmm=${file/.fasta/.fasta.transdecoder.pep-tmhmm.out}
Trinotate Trinotate.sqlite init --gene_trans_map ${transmap} --transcript_fasta ${file} --transdecoder_pep ${pep}
Trinotate Trinotate.sqlite LOAD_swissprot_blastp   ${blastp}
Trinotate Trinotate.sqlite LOAD_swissprot_blastx   ${blastx}
Trinotate Trinotate.sqlite LOAD_pfam   ${hmmscan}
Trinotate Trinotate.sqlite LOAD_tmhmm   ${tmhmm}
Trinotate Trinotate.sqlite LOAD_signalp   ${signalp}
Trinotate Trinotate.sqlite report -E 0.00001 > ${file%%}-trinotate_annotation_report.xls
done
