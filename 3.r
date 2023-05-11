#3. Duplicate the column with the partners, call it 'partner_original'. This is so we can populate the RTAs later, but in the meantime we need to replace the partners with an RTA grouping code for imputation purposes.
tariffs$PARTNER_original <- tariffs$PARTNER
