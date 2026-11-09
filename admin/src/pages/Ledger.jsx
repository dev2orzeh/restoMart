import React, { useState, useEffect, useMemo } from 'react';
import { useSearchParams } from 'react-router-dom';
import { 
  Box, 
  Typography, 
  Paper, 
  Table, 
  TableBody, 
  TableCell, 
  TableContainer, 
  TableHead, 
  TableRow, 
  Chip, 
  IconButton,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  MenuItem,
  Collapse,
  CircularProgress,
  InputAdornment
} from '@mui/material';
import KeyboardArrowDownIcon from '@mui/icons-material/KeyboardArrowDown';
import KeyboardArrowUpIcon from '@mui/icons-material/KeyboardArrowUp';
import PaymentIcon from '@mui/icons-material/Payment';
import RefreshIcon from '@mui/icons-material/Refresh';
import SearchIcon from '@mui/icons-material/Search';
import ClearIcon from '@mui/icons-material/Clear';
import { subscribeToLedgerAccounts, fetchLedgerTransactions, recordLedgerPayment, syncLedgerAccountsWithOrders } from '../services/firebase';
import { format } from 'date-fns';
import Loader from '../components/shared/Loader';

function Row(props) {
  const { row, onRecordPayment } = props;
  const [open, setOpen] = useState(false);
  const [transactions, setTransactions] = useState([]);
  const [loadingTxns, setLoadingTxns] = useState(false);

  const handleExpand = async () => {
    if (!open) {
      setLoadingTxns(true);
      try {
        const txns = await fetchLedgerTransactions(row.id);
        setTransactions(txns);
      } catch (err) {
        console.error("Failed to load transactions", err);
      }
      setLoadingTxns(false);
    }
    setOpen(!open);
  };

  return (
    <React.Fragment>
      <TableRow sx={{ '& > *': { borderBottom: 'unset' } }}>
        <TableCell>
          <IconButton aria-label="expand row" size="small" onClick={handleExpand}>
            {open ? <KeyboardArrowUpIcon /> : <KeyboardArrowDownIcon />}
          </IconButton>
        </TableCell>
        <TableCell component="th" scope="row">
          <Typography variant="body1" fontWeight="bold">{row.customerName}</Typography>
          <Typography variant="caption" color="text.secondary">{row.customerPhone} • {row.customerEmail}</Typography>
        </TableCell>
        <TableCell align="right">Rs. {(row.totalDebit || 0).toLocaleString()}</TableCell>
        <TableCell align="right">
          <Typography color="success.main" fontWeight="bold">
            Rs. {(row.totalCredit || 0).toLocaleString()}
          </Typography>
        </TableCell>
        <TableCell align="right">
          <Chip 
            label={(row.balance || 0) > 0 
              ? `Rs. ${(row.balance || 0).toLocaleString()} (Debt)` 
              : (row.balance || 0) < 0 
                ? `Rs. ${Math.abs(row.balance || 0).toLocaleString()} (Advance)` 
                : `Rs. 0 (Cleared)`} 
            color={(row.balance || 0) > 0 ? "error" : "success"}
            variant={(row.balance || 0) > 0 ? "filled" : "outlined"}
            sx={{ fontWeight: 'bold' }}
          />
        </TableCell>
        <TableCell align="center">
          <Button 
            variant="contained" 
            size="small"
            startIcon={<PaymentIcon />}
            onClick={() => onRecordPayment(row)}
          >
            Record Payment
          </Button>
        </TableCell>
      </TableRow>
      <TableRow>
        <TableCell style={{ paddingBottom: 0, paddingTop: 0 }} colSpan={6}>
          <Collapse in={open} timeout="auto" unmountOnExit>
            <Box sx={{ margin: 2 }}>
              <Typography variant="h6" gutterBottom component="div">
                Transaction History
              </Typography>
              {loadingTxns ? (
                <Typography variant="body2">Loading...</Typography>
              ) : (
                <Table size="small" aria-label="purchases">
                  <TableHead>
                    <TableRow>
                      <TableCell>Date</TableCell>
                      <TableCell>Description</TableCell>
                      <TableCell>Method</TableCell>
                      <TableCell align="right">Amount</TableCell>
                      <TableCell align="center">Type</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {transactions.map((txn) => (
                      <TableRow key={txn.id}>
                        <TableCell component="th" scope="row">
                          {txn.date ? format(txn.date.toDate(), 'MMM d, yyyy h:mm a') : 'N/A'}
                        </TableCell>
                        <TableCell>{txn.description}</TableCell>
                        <TableCell>
                          {txn.paymentMethod ? (
                            <Chip size="small" label={txn.paymentMethod.toUpperCase()} />
                          ) : '-'}
                        </TableCell>
                        <TableCell align="right" sx={{ fontWeight: 'bold' }}>
                          Rs. {(txn.amount || 0).toLocaleString()}
                        </TableCell>
                        <TableCell align="center">
                          {txn.type === 'debit' ? (
                            <Chip size="small" label="Order (Debit)" color="error" variant="outlined" />
                          ) : (
                            <Chip size="small" label="Payment (Credit)" color="success" />
                          )}
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              )}
            </Box>
          </Collapse>
        </TableCell>
      </TableRow>
    </React.Fragment>
  );
}

export default function Ledger() {
  const [searchParams, setSearchParams] = useSearchParams();
  const urlQ = searchParams.get('q') || '';
  const [searchQuery, setSearchQuery] = useState(urlQ);
  const [accounts, setAccounts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [paymentModalOpen, setPaymentModalOpen] = useState(false);
  const [selectedAccount, setSelectedAccount] = useState(null);
  
  const [amount, setAmount] = useState('');
  const [method, setMethod] = useState('Cash');
  const [note, setNote] = useState('');
  const [orderId, setOrderId] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  useEffect(() => {
    const qParam = searchParams.get('q') || '';
    setSearchQuery(qParam);
  }, [searchParams]);

  useEffect(() => {
    setLoading(true);
    const unsubscribe = subscribeToLedgerAccounts(
      (accs) => {
        setAccounts(accs);
      },
      () => {
        setLoading(false);
      }
    );
    return () => unsubscribe();
  }, []);

  const handleSearchChange = (val) => {
    setSearchQuery(val);
    if (val.trim()) {
      setSearchParams({ q: val }, { replace: true });
    } else {
      setSearchParams({}, { replace: true });
    }
  };

  const filteredAccounts = useMemo(() => {
    if (!searchQuery || !searchQuery.trim()) return accounts;
    const q = searchQuery.toLowerCase().trim();
    return accounts.filter((acc) => {
      const name = String(acc.customerName || '').toLowerCase();
      const phone = String(acc.customerPhone || '').toLowerCase();
      const email = String(acc.customerEmail || '').toLowerCase();
      return name.includes(q) || phone.includes(q) || email.includes(q);
    });
  }, [accounts, searchQuery]);

  const handleOpenPayment = (account) => {
    setSelectedAccount(account);
    setAmount('');
    setMethod('Cash');
    setNote('');
    setOrderId('');
    setPaymentModalOpen(true);
  };

  const handleClosePayment = () => {
    setPaymentModalOpen(false);
    setSelectedAccount(null);
  };

  const handleSubmitPayment = async () => {
    if (!amount || isNaN(amount) || amount <= 0) return;
    
    setIsSubmitting(true);
    try {
      await recordLedgerPayment(selectedAccount.id, amount, method, note, orderId);
      handleClosePayment();
    } catch (err) {
      console.error("Failed to record payment", err);
      alert("Error: " + err.message);
    }
    setIsSubmitting(false);
  };

  const [isSyncing, setIsSyncing] = useState(false);

  const handleSyncLedger = async () => {
    setIsSyncing(true);
    try {
      await syncLedgerAccountsWithOrders();
    } catch (e) {
      console.error(e);
    }
    setIsSyncing(false);
  };

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <div>
          <Typography variant="h4" fontWeight="bold">
            Business Khata (Ledger)
          </Typography>
          <Typography variant="body2" color="text.secondary" sx={{ mt: 0.5 }}>
            Real-time customer order debits, payments, and outstanding balances
          </Typography>
        </div>
        <Button
          variant="outlined"
          color="primary"
          startIcon={<RefreshIcon className={isSyncing ? "animate-spin" : ""} />}
          onClick={handleSyncLedger}
          disabled={isSyncing}
        >
          {isSyncing ? "Syncing Khata..." : "Sync Orders to Khata"}
        </Button>
      </Box>

      <Box sx={{ mb: 3, maxWidth: 380 }}>
        <TextField
          fullWidth
          size="small"
          placeholder="Search ledger by customer, phone, email..."
          value={searchQuery}
          onChange={(e) => handleSearchChange(e.target.value)}
          InputProps={{
            startAdornment: (
              <InputAdornment position="start">
                <SearchIcon color="action" fontSize="small" />
              </InputAdornment>
            ),
            endAdornment: searchQuery ? (
              <InputAdornment position="end">
                <IconButton size="small" onClick={() => handleSearchChange('')}>
                  <ClearIcon fontSize="small" />
                </IconButton>
              </InputAdornment>
            ) : null,
          }}
        />
      </Box>

      {loading ? (
        <Loader message="Syncing Business Khata & calculating balances..." />
      ) : (
        <TableContainer component={Paper} elevation={3}>
          <Table aria-label="collapsible table">
            <TableHead sx={{ backgroundColor: 'primary.main' }}>
              <TableRow>
                <TableCell />
                <TableCell sx={{ color: 'white', fontWeight: 'bold' }}>Customer</TableCell>
                <TableCell align="right" sx={{ color: 'white', fontWeight: 'bold' }}>Total Orders (Debit)</TableCell>
                <TableCell align="right" sx={{ color: 'white', fontWeight: 'bold' }}>Total Paid (Credit)</TableCell>
                <TableCell align="right" sx={{ color: 'white', fontWeight: 'bold' }}>Outstanding Balance</TableCell>
                <TableCell align="center" sx={{ color: 'white', fontWeight: 'bold' }}>Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {filteredAccounts.map((account) => (
                <Row key={account.id} row={account} onRecordPayment={handleOpenPayment} />
              ))}
              {filteredAccounts.length === 0 && (
                <TableRow>
                  <TableCell colSpan={6} align="center" sx={{ py: 3 }}>
                    <Typography variant="body1" color="text.secondary">
                      {searchQuery ? "No matching ledger accounts found." : "No ledger accounts found. Customers need to place at least one order to appear here."}
                    </Typography>
                  </TableCell>
                </TableRow>
              )}
            </TableBody>
          </Table>
        </TableContainer>
      )}

      {/* Payment Dialog */}
      <Dialog open={paymentModalOpen} onClose={handleClosePayment} maxWidth="sm" fullWidth>
        <DialogTitle>Record Payment for {selectedAccount?.customerName}</DialogTitle>
        <DialogContent>
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, mt: 1 }}>
            <Box sx={{ p: 2, bgcolor: 'error.light', borderRadius: 1, color: 'error.contrastText' }}>
              <Typography variant="subtitle2">Current Outstanding Balance</Typography>
              <Typography variant="h5" fontWeight="bold">Rs. {(selectedAccount?.balance || 0).toLocaleString()}</Typography>
            </Box>
            
            <TextField
              label="Amount Received (Rs)"
              type="number"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              fullWidth
              autoFocus
            />

            <TextField
              label="Order # (Optional)"
              value={orderId}
              onChange={(e) => setOrderId(e.target.value)}
              fullWidth
              placeholder="e.g. RM-35743 or 35743"
              helperText="Link payment to a specific order number (Optional)"
            />
            
            <TextField
              select
              label="Payment Method"
              value={method}
              onChange={(e) => setMethod(e.target.value)}
              fullWidth
            >
              <MenuItem value="Cash">Cash</MenuItem>
              <MenuItem value="JazzCash">JazzCash</MenuItem>
              <MenuItem value="EasyPaisa">EasyPaisa</MenuItem>
              <MenuItem value="Bank Transfer">Bank Transfer</MenuItem>
              <MenuItem value="Cheque">Cheque</MenuItem>
            </TextField>
            
            <TextField
              label="Note / Reference (Optional)"
              value={note}
              onChange={(e) => setNote(e.target.value)}
              fullWidth
              placeholder="e.g. TXN ID: 0918239"
            />
          </Box>
        </DialogContent>
        <DialogActions sx={{ p: 2, pt: 0 }}>
          <Button onClick={handleClosePayment} disabled={isSubmitting}>Cancel</Button>
          <Button 
            onClick={handleSubmitPayment} 
            variant="contained" 
            color="success"
            disabled={isSubmitting || !amount || amount <= 0}
          >
            {isSubmitting ? 'Recording...' : 'Record Payment'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
