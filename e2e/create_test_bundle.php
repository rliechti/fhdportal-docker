<?php
$params = getopt("n:p:T:c:o:d:r:s:xzfvh");

// Histology and primary-site values per indication, from the IMMUcan clinical value_dictionary.csv (ICD-O-3 strings as in the source).
const CANCERS = array(
    'breast' => array(
        'sex' => 'female',
        'histology' => array(
            'Invasive carcinoma of no special type (NST) (8500)',
            'Infiltrating ductular carcinoma (8521)',
            'Carcinoma, NOS (8010)',
            'Invasive carcinoma of no special type (NST) with medullary features (8500)',
            'Adenocarcinoma, NOS (8140)',
            'Invasive lobular carcinoma (8520)',
            'Infiltrating duct and lobular carcinoma (invasive type only) (8522)',
            'Apocrine adenocarcinoma (8401)',
            'Metaplastic carcinoma of no special type (8575)',
            'Ductal carcinoma in situ (8500)',
            'Neoplasm, malignant (8000)',
            'Invasive papillary carcinoma (8503)',
            'Mucinous carcinoma (8480)',
            'Infiltrating duct mixed with other types of carcinoma (8523)',
            'Invasive micropapillary carcinoma (8507)',
            'Pleomorphic carcinoma (8022)',
            'Intraductal papillary carcinoma (8503)',
            'Paget disease and infiltrating duct carcinoma of breast (8541)',
            'Infiltrating lobular mixed with other types of carcinoma (8524)',
            'Mucoepidermoid carcinoma (8430)',
            'Metaplastic carcinoma with mesenchymal differentiation, other types of mesenchymal differentiation (8575)',
            'Medullary carcinoma (8510)',
            'Intraductal papilloma with ductal carcinoma in situ (8503)',
            'Inflammatory carcinoma (8530)',
        ),
        'sites' => array(
            'Upper-outer quadrant of breast (C50.4)',
            'Breast, NOS (C50.9)',
            'Upper-inner quadrant of breast (C50.2)',
            'Lower-outer quadrant of breast (C50.5)',
            'Lower-inner quadrant of breast (C50.3)',
            'Central portion of breast (C50.1)',
            'Overlapping lesion of breast (C50.8)',
            'Nipple (C50.0)',
            'Axillary tail of breast (C50.6)',
        ),
    ),
    'lung' => array(
        'sex' => null,
        'histology' => array(
            'Adenocarcinoma (8140)',
            'Squamous cell carcinoma (8070)',
            'Carcinoma, NOS (8010)',
            'Acinar adenocarcinoma (8551)',
            'Keratinizing squamous cell carcinoma (8071)',
            'Solid adenocarcinoma (8230)',
            'Non-keratinizing squamous cell carcinoma (8072)',
            'Large cell carcinoma (8012)',
            'Adenosquamous carcinoma (8560)',
            'Squamous cell carcinoma in situ (8070)',
            'Pleomorphic carcinoma (8022)',
            'Papillary adenocarcinoma (8260)',
            'Large cell neuroendocrine carcinoma (8013)',
            'Lepidic adenocarcinoma (8250)',
            'Micropapillary adenocarcinoma (8265)',
            'Invasive mucinous adenocarcinoma (8253)',
        ),
        'sites' => array(
            'Lung, NOS (C34.9)',
            'Upper lobe, lung (C34.1)',
            'Lower lobe, lung (C34.3)',
            'Middle lobe, lung (C34.2)',
            'Main bronchus (C34.0)',
            'Overlapping lesion of lung (C34.8)',
        ),
    ),
    'kidney' => array(
        'sex' => null,
        'histology' => array(
            'Clear cell renal cell carcinoma (8310)',
            'Carcinoma, NOS (8010)',
            'Renal cell carcinoma, unclassified (8312)',
            'Papillary renal cell carcinoma (8260)',
            'Chromophobe renal cell carcinoma (8317)',
        ),
        'sites' => array(
            'Kidney, NOS (C64.9)',
        ),
    ),
    'colorectal' => array(
        'sex' => null,
        'histology' => array(
            'Adenocarcinoma (8140)',
            'Carcinoma, NOS (8010)',
            'Mucinous adenocarcinoma (8480)',
            'Adenocarcinoma in situ (8140)',
        ),
        'sites' => array(
            'Sigmoid colon (C18.7)',
            'Rectum, NOS (C20.9)',
            'Ascending colon (C18.2)',
            'Cecum (C18.0)',
            'Descending colon (C18.6)',
            'Rectosigmoid junction (C19.9)',
            'Transverse colon (C18.4)',
            'Colon, NOS (C18.9)',
        ),
    ),
    'headneck' => array(
        'sex' => null,
        'histology' => array(
            'Squamous cell carcinoma (8070)',
            'Carcinoma, NOS (8010)',
            'Conventional squamous cell carcinoma (8070)',
            'Squamous cell carcinoma, HPV-negative (8086)',
            'Non-keratinizing squamous cell carcinoma (8072)',
            'Keratinizing squamous cell carcinoma (8071)',
            'Squamous cell carcinoma, HPV-positive (8085)',
            'Basaloid squamous cell carcinoma (8083)',
            'Neoplasm, malignant (8000)',
            'Spindle cell squamous cell carcinoma (8074)',
            'Papillary squamous cell carcinoma (8052)',
            'Verrucous squamous cell carcinoma (8051)',
        ),
        'sites' => array(
            'Oropharynx, NOS (C10.9)',
            'Hypopharynx, NOS (C13.9)',
            'Overlapping lesion of lip, oral cavity, and pharynx (C14.8)',
            'Larynx, NOS (C32.9)',
            'Tongue, NOS (C02.9)',
            'Base of tongue, NOS (C01.9)',
            'Floor of mouth, NOS (C04.9)',
            'Supraglottis (laryngeal surface) (C32.1)',
            'Pyriform sinus (C12.9)',
            'Tonsil, NOS (C09.9)',
            'Glottis (C32.0)',
            'Overlapping lesion of other and unspecified parts of mouth (C06.8)',
            'Border of tongue (C02.1)',
            'Soft palate, NOS (C05.1)',
            'Maxillary sinus (C31.0)',
            'Palate, NOS (C05.9)',
            'Lower gum (C03.1)',
            'Lateral floor of mouth (C04.1)',
            'Posterior wall of oropharynx (C10.3)',
            'Tonsillar fossa (C09.0)',
            'Subglottis (C32.2)',
            'Vallecula (C10.0)',
            'Retromolar area (C06.2)',
            'Mouth, NOS (C06.9)',
            'Gum, NOS (C03.9)',
        ),
    ),
);

const GENOME = 'GRCh38.p14: GCA_000001405.29';

function pick(array $items)
{
    return $items[mt_rand(0, count($items) - 1)];
}

function random_date(string $from, string $to): string
{
    return date('Y-m-d', mt_rand(strtotime($from), strtotime($to)));
}

function tsv(array $header, array $rows): string
{
    $lines = array(implode("\t", $header));
    foreach ($rows as $row) {
        $values = array();
        foreach ($header as $col) {
            $value = (string) ($row[$col] ?? '');
            if (preg_match('/[\t\r\n"]/', $value)) {
                throw new Exception("Error: illegal character in $col value: $value");
            }
            $values[] = $value;
        }
        $lines[] = implode("\t", $values);
    }
    return implode("\n", $lines) . "\n";
}

function build(string $name, int $patients, int $maxTumors, string $cancer, string $created, string $released, bool $extras): array
{
    $pool = CANCERS[$cancer];
    $samples = $runs = $analyses = $sizes = array();
    $wxsRuns = $rnaRuns = $variantAnalyses = $rnaAnalyses = array();
    $expWxs = "WXS $name";
    $expRna = "RNAseq $name";

    $ids = range(1, 1999);
    shuffle($ids);

    foreach (array_slice($ids, 0, $patients) as $n) {
        $pid = sprintf('%s-%04d', $name, $n);
        $phenotype = pick($pool['histology']);
        $site = pick($pool['sites']);
        $sex = $pool['sex'] ?? pick(array('female', 'male'));
        $runDate = random_date('2022-01-01', $created);

        $sample = function (string $kind, string $assay, string $description, string $caseControl, string $organismPart, $conc) use (&$samples, $phenotype, $pid, $sex) {
            $alias = "$pid-$kind-$assay-01";
            $samples[] = array(
                'alias' => $alias,
                'title' => $alias,
                'cell_line' => '',
                'phenotype' => $phenotype,
                'subject_id' => $pid,
                'description' => $description,
                'biosample_id' => $alias,
                'case_control' => $caseControl,
                'organism_part' => $organismPart,
                'biological_sex' => $sex,
                'DNA_concentration' => $conc,
            );
            return $alias;
        };
        $run = function (string $experiment, string $alias) use (&$runs, &$sizes, $runDate) {
            $files = array();
            $size = mt_rand(2000000000, 12000000000);
            foreach (array(1, 2) as $mate) {
                $file = "$alias.$mate.fastq.gz.c4gh";
                $files[] = $file;
                $sizes[$file] = (int) ($size * mt_rand(95, 105) / 100);
            }
            $title = strtok($experiment, ' ') . '_' . $alias;
            $runs[] = array(
                'title' => $title,
                'experiment' => $experiment,
                'sample' => $alias,
                'files' => implode(';', $files),
                'run_file_type' => 'fastq',
                'run_date' => $runDate,
            );
            return $title;
        };
        $conc = function () {
            return rtrim(rtrim(number_format(mt_rand(50, 2000) / 10, 1, '.', ''), '0'), '.');
        };

        $germline = $sample('GERMLINE', 'DNA', 'Blood GERMLINE. DNA', 'control', $site, $conc());
        $wxsRuns[] = $run($expWxs, $germline);

        foreach (range(1, mt_rand(1, $maxTumors)) as $t) {
            $kind = sprintf('TUMOR-%02d', $t);
            $part = "$site: Primary tumor";
            $dna = $sample($kind, 'DNA', 'Fixed tissue. DNA', 'case', $part, $conc());
            $rna = $sample($kind, 'RNA', 'Fixed tissue. RNA', 'case', $part, $conc());
            $wxsRuns[] = $run($expWxs, $dna);
            $rnaRuns[] = $run($expRna, $rna);

            $rnaFile = $rna . '_counts.txt.c4gh';
            $rnaTitle = "Transcriptomics for $pid-$kind";
            $analyses[] = array(
                'files' => $rnaFile,
                'title' => $rnaTitle,
                'platform' => 'Illumina',
                'genome_id' => GENOME,
                'description' => 'Transcriptomics',
                'analysis_type' => 'SAMPLE PHENOTYPE',
                'experiment_types' => 'Transcriptomics',
                'samples' => $rna,
                'experiments' => $expRna,
            );
            $sizes[$rnaFile] = mt_rand(1100000, 1400000);
            $rnaAnalyses[] = $rnaTitle;

            $vcfFiles = array("{$dna}_vs_{$germline}_SNP.vcf.gz.c4gh", "{$dna}_vs_{$germline}_CNV.vcf.gz.c4gh");
            $vcfTitle = "Variant calling for $pid-$kind";
            $analyses[] = array(
                'files' => implode(';', $vcfFiles),
                'title' => $vcfTitle,
                'platform' => 'Illumina',
                'genome_id' => GENOME,
                'description' => 'Variant calling',
                'analysis_type' => 'SEQUENCE VARIATION',
                'experiment_types' => 'Genotyping by sequencing',
                'samples' => "$dna;$germline",
                'experiments' => $expWxs,
            );
            $sizes[$vcfFiles[0]] = mt_rand(15000, 60000);
            $sizes[$vcfFiles[1]] = mt_rand(2000, 20000);
            $variantAnalyses[] = $vcfTitle;
        }
    }

    if ($extras) {
        $extraSite = pick($pool['sites']);
        $samples[] = array(
            'alias' => "$name-E2E-TUMOR-01-DNA-01",
            'title' => "$name-E2E-TUMOR-01-DNA-01",
            'cell_line' => '',
            'phenotype' => pick($pool['histology']),
            'subject_id' => "$name-E2E",
            'description' => 'E2E test sample - to be deleted',
            'biosample_id' => "$name-E2E-TUMOR-01-DNA-01",
            'case_control' => 'case',
            'organism_part' => "$extraSite: Primary tumor",
            'biological_sex' => $pool['sex'] ?? pick(array('female', 'male')),
            'DNA_concentration' => rtrim(rtrim(number_format(mt_rand(50, 2000) / 10, 1, '.', ''), '0'), '.'),
        );
    }

    $study = array(array(
        'status' => 'draft',
        'creation_date' => $created,
        'last_update' => $created,
        'title' => "TEST$patients $name study",
        'description' => "Test export of scrambled IMMUcan $name dataset. Limited to $patients " . ($patients == 1 ? 'patient' : 'patients'),
        'study_type' => 'Cancer Genomics',
    ) + ($extras ? array('e2e_extra_attribute' => 'to be removed during the E2E test') : array()));
    $experiments = array(
        array(
            'title' => $expWxs,
            'library_layout' => 'PAIRED',
            'library_source' => 'GENOMIC',
            'library_strategy' => 'WXS',
            'library_selection' => 'RANDOM',
            'design_description' => 'SureSelect Whole Exome Sequencing',
            'instrument_model_id' => 'ILLUMINA: Illumina Genome Analyzer II',
            'library_construction_protocol' => 'Agilent Sureselect All Exom 2.0.1',
            'paired_nominal_length' => 250
        ),
        array(
            'title' => $expRna,
            'library_layout' => 'PAIRED',
            'library_source' => 'GENOMIC',
            'library_strategy' => 'RNA-Seq',
            'library_selection' => 'RANDOM',
            'design_description' => 'KAPA RNA-seq',
            'instrument_model_id' => 'ILLUMINA: Illumina Genome Analyzer II',
            'library_construction_protocol' => 'KAPA RNA HyperPrep with RiboErase (HMR) with KAPA Globin Depletion Hybridization Oligos (Roche)',
            'paired_nominal_length' => 250
        ),
        array(
            'title' => "RNAseq rescue $name",
            'library_layout' => 'PAIRED',
            'library_source' => 'GENOMIC',
            'library_strategy' => 'RNA-Seq',
            'library_selection' => 'RANDOM',
            'design_description' => 'Takara RNA-seq',
            'instrument_model_id' => 'ILLUMINA: Illumina Genome Analyzer II',
            'library_construction_protocol' => 'SMART-Seq Stranded (Takara Bio)',
            'paired_nominal_length' => 250
        ),
    );
    $datasets = array(
        array(
            'title' => "Transcriptomics for $name cohort",
            'description' => "Transcriptomics of Tumor samples on $name cohort",
            'dataset_types' => 'Transcriptome profiling by high-throughput sequencing',
            'runs' => implode(';', $rnaRuns),
            'analyses' => implode(';', $rnaAnalyses),
            'released_date' => $released
        ),
        array(
            'title' => "Variant calling for $name cohort",
            'description' => "Tumor versus Germline variant calling on $name cohort",
            'dataset_types' => 'Genomic variant calling;Exome sequencing',
            'runs' => implode(';', $wxsRuns),
            'analyses' => implode(';', $variantAnalyses),
            'released_date' => $released
        ),
    );

    return array(
        'study' => array(array_merge(array('status', 'creation_date', 'last_update', 'title', 'description', 'study_type'), $extras ? array('e2e_extra_attribute') : array()), $study),
        'samples' => array(array('alias', 'title', 'cell_line', 'phenotype', 'subject_id', 'description', 'biosample_id', 'case_control', 'organism_part', 'biological_sex', 'DNA_concentration'), $samples),
        'experiments' => array(array('title', 'library_layout', 'library_source', 'library_strategy', 'library_selection', 'design_description', 'instrument_model_id', 'library_construction_protocol', 'paired_nominal_length'), $experiments),
        'runs' => array(array('title', 'experiment', 'sample', 'files', 'run_file_type', 'run_date'), $runs),
        'analyses' => array(array('files', 'title', 'platform', 'genome_id', 'description', 'analysis_type', 'experiment_types', 'samples', 'experiments'), $analyses),
        'datasets' => array(array('title', 'description', 'dataset_types', 'runs', 'analyses', 'released_date'), $datasets),
        'sizes' => $sizes,
    );
}

function main(array $opt)
{
    $name = $opt['n'];
    if (!preg_match('/^[A-Za-z0-9][A-Za-z0-9_-]*$/', $name)) {
        throw new Exception("Error: invalid name '$name' (letters, digits, '-' and '_' only)");
    }
    if (!isset(CANCERS[$opt['c']])) {
        throw new Exception("Error: unknown cancer type '" . $opt['c'] . "' (" . implode(', ', array_keys(CANCERS)) . ")");
    }
    if ($opt['p'] < 1 || $opt['p'] > 500 || $opt['T'] < 1 || $opt['T'] > 20) {
        throw new Exception("Error: patients must be 1-500 and tumors per patient 1-20");
    }
    foreach (array($opt['d'], $opt['r']) as $date) {
        if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $date) || strtotime($date) === false) {
            throw new Exception("Error: invalid date '$date' (expected YYYY-MM-DD)");
        }
    }
    $dir = rtrim($opt['o'], '/') . '/' . $name;
    if (file_exists($dir) && !$opt['f']) {
        throw new Exception("Error: $dir already exists (use -f to overwrite)");
    }
    if (!is_dir($dir) && !mkdir($dir, 0750, true)) {
        throw new Exception("Error: cannot create $dir");
    }

    mt_srand($opt['s']);
    $bundle = build($name, $opt['p'], $opt['T'], $opt['c'], $opt['d'], $opt['r'], $opt['x']);

    $types = array(
        'study' => 'Study',
        'samples' => 'Sample',
        'experiments' => 'MolecularExperiment',
        'runs' => 'MolecularRun',
        'analyses' => 'MolecularAnalysis',
        'datasets' => 'Dataset'
    );
    $manifest = "version: 1\nfiles:\n";
    $written = array();
    foreach ($types as $kind => $type) {
        $file = "{$name}_{$kind}.tsv";
        file_put_contents("$dir/$file", tsv($bundle[$kind][0], $bundle[$kind][1]));
        $manifest .= "    -\n        file_name: $file\n        resource_type: $type\n";
        $written[] = $file;
    }
    file_put_contents("$dir/manifest.yaml", $manifest);

    $sizes = '';
    foreach ($bundle['sizes'] as $file => $size) {
        $sizes .= "$file\t$size\n";
    }
    file_put_contents("$dir/file_sizes.tsv", $sizes);

    if ($opt['z']) {
        if (!class_exists('ZipArchive')) {
            throw new Exception("Error: the PHP zip extension is required for -z");
        }
        $zipPath = "$dir/$name.zip";
        @unlink($zipPath);
        $zip = new ZipArchive();
        if ($zip->open($zipPath, ZipArchive::CREATE) !== true) {
            throw new Exception("Error: cannot create $zipPath");
        }
        foreach (array_merge($written, array('manifest.yaml')) as $file) {
            $zip->addFile("$dir/$file", $file);
        }
        $zip->close();
    }

    fwrite(STDOUT, sprintf(
        "%s: %d patients, %d samples, %d runs, %d analyses, %d datasets, %d files (seed %d)" . PHP_EOL,
        $dir,
        $opt['p'],
        count($bundle['samples'][1]),
        count($bundle['runs'][1]),
        count($bundle['analyses'][1]),
        count($bundle['datasets'][1]),
        count($bundle['sizes']),
        $opt['s']
    ));
    if ($opt['v']) {
        fwrite(STDOUT, "Next steps:" . PHP_EOL);
        fwrite(STDOUT, "  fega validate $dir" . PHP_EOL);
        fwrite(STDOUT, "  php create_files.php -d $dir -t <dev|staging> [-s FILE] [-u] -v   (create_files.php lives in upload2sda)" . PHP_EOL);
        if (!$opt['z']) {
            fwrite(STDOUT, "  re-run with -z -f -s {$opt['s']} -d {$opt['d']} to also create $name.zip" . PHP_EOL);
        }
    }
}

function print_usage()
{
    fwrite(STDOUT, "usage: php " . basename(__FILE__) . " -n <name> [-p <patients>] [-T <tumors>] [-c <cancer>] [-o <dir>] [-d <date>] [-r <date>] [-s <seed>] [-x] [-z] [-f] [-v] [-h]" . PHP_EOL);
    fwrite(STDOUT, "  -n <name>     : bundle name, used for the directory, file names and aliases (e.g. TEST-STA07)" . PHP_EOL);
    fwrite(STDOUT, "  -p <patients> : number of patients. Default: 3" . PHP_EOL);
    fwrite(STDOUT, "  -T <tumors>   : max tumor samples (DNA+RNA pairs) per patient. Default: 2" . PHP_EOL);
    fwrite(STDOUT, "  -c <cancer>   : " . implode(' | ', array_keys(CANCERS)) . ". Default: random" . PHP_EOL);
    fwrite(STDOUT, "  -o <dir>      : output parent directory. Default: current directory" . PHP_EOL);
    fwrite(STDOUT, "  -d <date>     : study creation date (YYYY-MM-DD). Default: today" . PHP_EOL);
    fwrite(STDOUT, "  -r <date>     : dataset release date (YYYY-MM-DD). Default: creation date" . PHP_EOL);
    fwrite(STDOUT, "  -s <seed>     : random seed, to regenerate the exact same bundle. Default: random" . PHP_EOL);
    fwrite(STDOUT, "  -x            : E2E test extras: one additional sample without runs and one additional study extra attribute (e2e_extra_attribute), both to be removed during the test" . PHP_EOL);
    fwrite(STDOUT, "  -z            : also create <name>.zip, ready to upload on the portal" . PHP_EOL);
    fwrite(STDOUT, "  -f            : overwrite an existing bundle directory" . PHP_EOL);
    fwrite(STDOUT, "  -v            : verbose (print next steps)" . PHP_EOL);
    fwrite(STDOUT, "  -h            : print this help" . PHP_EOL);
}

$name = $params['n'] ?? '';
$help = isset($params['h']);
if (!$name || $help) {
    print_usage();
    exit($help ? 0 : 1);
}
$today = date('Y-m-d');
$created = $params['d'] ?? $today;
$opt = array(
    'n' => $name,
    'p' => (int) ($params['p'] ?? 3),
    'T' => (int) ($params['T'] ?? 2),
    'c' => $params['c'] ?? '',
    'o' => $params['o'] ?? getcwd(),
    'd' => $created,
    'r' => $params['r'] ?? $created,
    'x' => isset($params['x']),
    's' => isset($params['s']) ? (int) $params['s'] : random_int(1, 2147483647),
    'z' => isset($params['z']),
    'f' => isset($params['f']),
    'v' => isset($params['v']),
);
if ($opt['c'] === '') {
    mt_srand($opt['s']);
    $opt['c'] = pick(array_keys(CANCERS));
}

try {
    main($opt);
} catch (Exception $e) {
    fwrite(STDERR, $e->getMessage() . PHP_EOL);
    exit(1);
}
