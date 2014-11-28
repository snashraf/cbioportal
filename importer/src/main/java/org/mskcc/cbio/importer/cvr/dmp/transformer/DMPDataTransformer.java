/*
 *  Copyright (c) 2014 Memorial Sloan-Kettering Cancer Center.
 * 
 *  This library is distributed in the hope that it will be useful, but
 *  WITHOUT ANY WARRANTY, WITHOUT EVEN THE IMPLIED WARRANTY OF
 *  MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.  The software and
 *  documentation provided hereunder is on an "as is" basis, and
 *  Memorial Sloan-Kettering Cancer Center 
 *  has no obligations to provide maintenance, support,
 *  updates, enhancements or modifications.  In no event shall
 *  Memorial Sloan-Kettering Cancer Center
 *  be liable to any party for direct, indirect, special,
 *  incidental or consequential damages, including lost profits, arising
 *  out of the use of this software and its documentation, even if
 *  Memorial Sloan-Kettering Cancer Center 
 *  has been advised of the possibility of such damage.
 */
package org.mskcc.cbio.importer.cvr.dmp.transformer;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.common.collect.FluentIterable;
import com.google.inject.internal.Lists;
import com.google.inject.internal.Preconditions;

import java.io.File;
import java.io.IOException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;

import org.apache.log4j.Logger;
import org.mskcc.cbio.importer.cvr.dmp.model.DmpData;
import org.mskcc.cbio.importer.cvr.dmp.model.Result;
import org.mskcc.cbio.importer.cvr.dmp.persistence.file.DMPTumorTypeSampleMapManager;
import org.mskcc.cbio.importer.persistence.staging.segment.SegmentFileHandlerImpl;
import org.mskcc.cbio.importer.persistence.staging.util.StagingUtils;
import org.mskcc.cbio.importer.persistence.staging.TsvStagingFileHandler;
import org.mskcc.cbio.importer.persistence.staging.clinical.ClinicalDataFileHandlerImpl;
import org.mskcc.cbio.importer.persistence.staging.cnv.CnvFileHandlerImpl;
import org.mskcc.cbio.importer.persistence.staging.fusion.FusionModel;
import org.mskcc.cbio.importer.persistence.staging.mutation.MutationFileHandlerImpl;

/*
 Responsible for transforming the DMP data encapsulated in the DmpData object
 graph into a set of MAF files
 Inputs: 1. The DMP data as a Java object graph
 2. A reference to a DMPStagingFileManagerOld for writing the DMP staging
 data
 3. A List of DMPTransformable implementations responsible for 
 transforming specific components of the DMP data
 */
public class DMPDataTransformer {

    private final static Logger logger = Logger.getLogger(DMPDataTransformer.class);
    
    private  List<DMPDataTransformable> transformableList;
    private  DMPTumorTypeSampleMapManager tumorTypeMap;
    private  Path stagingDirectoryPath;

    public DMPDataTransformer(Path aPath) {
            if(StagingUtils.isValidStagingDirectoryPath(aPath)) {
                this.stagingDirectoryPath = aPath;
                registerTransformables();
            }
    }

    private void registerTransformables() {
        // instantiate and register data transformers
        //SNPs
        this.transformableList = Lists.newArrayList((DMPDataTransformable)
                new DmpSnpTransformer(new MutationFileHandlerImpl(),
                        stagingDirectoryPath));
        //CNVs
        this.transformableList.add((DMPDataTransformable)
                new DmpCnvTransformer( new CnvFileHandlerImpl(),
                        stagingDirectoryPath));
        //Metadata
        this.transformableList.add((DMPDataTransformable) new DmpMetadataTransformer
            ( new ClinicalDataFileHandlerImpl(), stagingDirectoryPath));

        //Structural Variants
        this.transformableList.add((DMPDataTransformable) new DmpFusionTransformer
                (new MutationFileHandlerImpl(),stagingDirectoryPath) );
        // segment data
         this.transformableList.add( (DMPDataTransformable) new DmpSegmentDataTransformer
                 ( new MutationFileHandlerImpl() , stagingDirectoryPath));
        // this.tumorTypeMap = new DMPTumorTypeSampleMapManager(this.fileManager);
    }

    /*
     transform the DMP data into variant type-specific MAF files
     return a Set of processed SMP sample ids
     */

    public List<String> transform(DmpData data) {
        Preconditions.checkArgument(null != data, "DMP data is required for transformation");
        
        // process the tumor types
        //this.tumorTypeMap.updateTumorTypeSampleMap(data.getResults());
        // invoke the type specific transformers on the DMP data
        for (DMPDataTransformable transformable : this.transformableList) {
            transformable.transform(data);
        }

        return FluentIterable.from(data.getResults())
        .transform(new com.google.common.base.Function<Result, String>() {
            @Override
            public String apply(Result result) {
                return result.getMetaData().getDmpSampleId();
            }
        }).toList();
    }

    // main method for stand alone testing
    public static void main(String...args){
        ObjectMapper OBJECT_MAPPER = new ObjectMapper();
        String tempDir = "/tmp/cvr/dmp";
        File tmpDir = new File(tempDir);
        tmpDir.mkdirs();
        Path stagingFileDirectory = Paths.get(tempDir);
        DMPDataTransformer transformer = new DMPDataTransformer(stagingFileDirectory);
        try {
            DmpData data = OBJECT_MAPPER.readValue(new File("/tmp/cvr/dmp/result-sv.json"), DmpData.class);
            transformer.transform(data);

        } catch (IOException ex) {
            logger.error(ex.getMessage());
        }
    }

}