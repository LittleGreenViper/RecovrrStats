/*
 © Copyright 2024, Little Green Viper Software Development LLC
*/

import SwiftUI
import TabularData
import Charts

/* ###################################################################################################################################### */
// MARK: - Adds Chart Plottable Stuff -
/* ###################################################################################################################################### */
public extension RCVST_DataProvider.Row {
    /* ############################################################################################################################## */
    // MARK: This is used to refine the total, by the types of users.
    /* ############################################################################################################################## */
    /**
     
     */
    struct UserType {
        /* ########################################################################################################################## */
        // MARK: This is used to define the types of users.
        /* ########################################################################################################################## */
        /**
         
         */
        enum UserTypes: String {
            /* ###################################################### */
            /**
             */
            case active
            
            /* ###################################################### */
            /**
             */
            case new
        }
        
        /* ########################################################## */
        /**
         */
        let category: UserTypes
        
        /* ########################################################## */
        /**
         */
        let value: Int
        
        /* ########################################################## */
        /**
         */
        let group: Int
    }
    
    /* ############################################################## */
    /**
     */
    var userTypes: [UserType] {
        [UserType(category: .active, value: activeUsers, group: 1),
         UserType(category: .new, value: newUsers, group: 2)]
    }
}

/* ###################################################################################################################################### */
// MARK: - Adds Chart Plottable Stuff -
/* ###################################################################################################################################### */
public extension RCVST_DataProvider {
    /* ############################################################## */
    /**
     */
    var plottableUserData: [Date: [Row.UserType]] {
        reduce([Date: [Row.UserType]]()) { current, next in
            guard let key = next.sampleDate else { return current }
            var new = current
            new[key] = next.userTypes
            
            return new
        }
    }
}

/* ###################################################################################################################################### */
// MARK: - Main Content View -
/* ###################################################################################################################################### */
/**
 */
struct RCVST_Chart1View: View {
    /* ################################################################## */
    /**
     This is the actual dataframe wrapper for the stats.
     */
    @State var data: RCVST_DataProvider

    /* ################################################################## */
    /**
     This is the layout for this screen.
     */
    var body: some View {
        GeometryReader { inGeometry in
            ScrollView {
                VStack {
                }
                .padding()
                .frame(
                    minWidth: inGeometry.size.width,
                    maxWidth: inGeometry.size.width,
                    minHeight: inGeometry.size.height,
                    maxHeight: .infinity,
                    alignment: .topLeading
                )
            }
        }
    }
}
